#Requires -Version 5.1
<#
.SYNOPSIS
Resend a single BU notification email that was previously sent by
Invoke-AuditLog.ps1, using the archived body in sent-emails.json.

.DESCRIPTION
The single approved escape hatch for operators when a BU says a report never
arrived. Does NOT re-run analysis and does NOT bypass the ledger; it appends
a `resent` record so the send is still traceable. Cannot resend content that
was never captured - if sent-emails.json for the specified (RunId, TaskName,
BU) is missing, this errors out and the operator must file it up the chain.

The SMTP context (From, SmtpServer, KeyName cert alias, Port) is read from
the stored record itself. The cert object is re-fetched via Get-Cert.

.PARAMETER RunId
The run identifier under runs/ that produced the original send. Format
'yyyyMMdd_HHmmss'. Find it in latest-run.json or the workflow log.

.PARAMETER TaskName
The task Name from analysis_task.config.psd1 (e.g. 'device-msms').

.PARAMETER BU
BU identifier used in the ledger. See DEPLOYMENT_QA.md for the value table:
per-BU names ('Private Credit & Equity', 'AbC TestChina', ...) or summary
tokens ('MSMS', 'MSBIC', 'ALL').

.PARAMETER ConfigPath
Path to analysis_task.config.psd1. Standard resolution rules apply.

.PARAMETER DryRun
Print what would be sent and exit 0. No send, no ledger append.

.EXAMPLE
.\Invoke-BuMailResend.ps1 -RunId 20260528_140000 -TaskName device-msms -BU 'Real Assets'

.EXAMPLE
.\Invoke-BuMailResend.ps1 -RunId 20260528_140000 -TaskName mail-comm -BU 'ALL' -DryRun

.NOTES
Exit codes:
  0 - resend succeeded (or DryRun completed)
  1 - lookup / send failed
  2 - no matching prior send found for the given (RunId, TaskName, BU)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d{8}_\d{6}$')]
    [string]$RunId,
    [Parameter(Mandatory = $true)]
    [string]$TaskName,
    [Parameter(Mandatory = $true)]
    [string]$BU,
    [string]$ConfigPath,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path $scriptRoot 'wecom_analysis_comm.psm1'
if (-not (Test-Path $modulePath -PathType Leaf)) { throw "Module not found: $modulePath" }
Import-Module $modulePath -Force

$ConfigPath = Resolve-AuditConfigPath -ConfigPath $ConfigPath -ScriptRoot $scriptRoot
if (-not (Test-Path $ConfigPath -PathType Leaf)) { throw "Config file not found: $ConfigPath" }
$config = Import-PowerShellDataFile -Path $ConfigPath

$logRoot   = Resolve-AuditOutputRoot -Config $config -ConfigPath $ConfigPath
$runsRoot  = [System.IO.Path]::Combine($logRoot, 'runs')
$runFolder = [System.IO.Path]::Combine($runsRoot, $RunId)

if (-not (Test-Path -LiteralPath $runFolder -PathType Container)) {
    throw "Run folder not found: $runFolder"
}

$tasksRoot = [System.IO.Path]::Combine($runFolder, 'tasks')
if (-not (Test-Path -LiteralPath $tasksRoot -PathType Container)) {
    throw "Tasks folder not found: $tasksRoot"
}

# Locate the task by scanning sent-emails.json envelopes for a matching TaskName.
$matched = $null
foreach ($candidate in @(Get-ChildItem -LiteralPath $tasksRoot -Directory)) {
    $sePath = Join-Path $candidate.FullName 'sent-emails.json'
    if (-not (Test-Path -LiteralPath $sePath -PathType Leaf)) { continue }
    try {
        $data = Get-Content -LiteralPath $sePath -Raw | ConvertFrom-Json
    }
    catch { continue }
    if (-not $data) { continue }
    if (-not $data.PSObject.Properties['TaskName'] -or $data.TaskName -ne $TaskName) { continue }
    $matched = [pscustomobject]@{
        SentEmailsPath = $sePath
        Envelope       = $data
        TaskFolder     = $candidate.FullName
    }
    break
}

if (-not $matched) {
    Write-Warning "No task '$TaskName' with sent-emails.json found under run '$RunId'."
    exit 2
}

# Find the latest send for the requested BU. Emails array is chronological.
$emails = @()
if ($matched.Envelope.PSObject.Properties['Emails']) {
    $emails = @($matched.Envelope.Emails)
}

$target = $emails | Where-Object { $_.PSObject.Properties['BU'] -and $_.BU -eq $BU } | Select-Object -Last 1
if (-not $target) {
    Write-Warning "No prior send for BU '$BU' in task '$TaskName' of run '$RunId'."
    Write-Host "Available BUs in this run:" -ForegroundColor Yellow
    foreach ($e in $emails) { Write-Host "  - $($e.BU) [$($e.Status)] $($e.SentAt)" }
    exit 2
}

$cycleId = if ($matched.Envelope.PSObject.Properties['Cycle']) { [string]$matched.Envelope.Cycle } else { 'unknown' }

Write-Host "Found prior send:" -ForegroundColor Cyan
Write-Host "  Cycle:        $cycleId"
Write-Host "  Task:         $TaskName"
Write-Host "  BU:           $BU"
Write-Host "  From:         $($target.From)"
Write-Host "  To:           $((@($target.Recipients)) -join ', ')"
Write-Host "  Cc:           $(if ($target.PSObject.Properties['Cc']) { $target.Cc } else { '' })"
Write-Host "  Subject:      $($target.Subject)"
Write-Host "  ContentHash:  $($target.ContentHash)"
Write-Host "  OriginalSent: $($target.SentAt)"
Write-Host "  SmtpServer:   $($target.SmtpServer)"
Write-Host "  KeyName:      $($target.KeyName)"
Write-Host ""

if ($DryRun) {
    Write-Host 'DryRun: no send performed, no ledger append.' -ForegroundColor Yellow
    exit 0
}

# Fetch the cert freshly from the local store using the stored KeyName.
$cert = Get-Cert -KeyName $target.KeyName
if (-not $cert) {
    throw "Failed to retrieve certificate for KeyName '$($target.KeyName)'."
}

$port = if ($target.PSObject.Properties['Port']) { [int]$target.Port } else { 2587 }

$sendArgs = @{
    From       = [string]$target.From
    To         = @($target.Recipients)
    Subject    = [string]$target.Subject
    Body       = [string]$target.Body
    SmtpServer = [string]$target.SmtpServer
    KeyName    = [string]$target.KeyName
    Cert       = $cert
    Port       = $port
}
if ($target.PSObject.Properties['Cc'] -and $target.Cc) {
    $sendArgs.Cc = [string]$target.Cc
}

try {
    Send-Mail @sendArgs
}
catch {
    Write-Warning "Send failed: $($_.Exception.Message)"
    exit 1
}

Write-Host 'Resend successful.' -ForegroundColor Green

# Append 'resent' record to ledger and to the same sent-emails.json.
$now = (Get-Date).ToString('o')
$ledgerPath = Get-MailLedgerPath -Config $config -ConfigPath $ConfigPath

$ledgerEntry = [ordered]@{
    Cycle       = $cycleId
    Task        = $TaskName
    BU          = $BU
    Recipients  = @($target.Recipients)
    Subject     = [string]$target.Subject
    ContentHash = [string]$target.ContentHash
    SentAt      = $now
    RunId       = $RunId
    Status      = 'resent'
}
Add-MailLedgerEntry -LedgerPath $ledgerPath -Entry $ledgerEntry

$resendRecord = [ordered]@{
    BU          = $BU
    Recipients  = @($target.Recipients)
    Cc          = if ($target.PSObject.Properties['Cc']) { $target.Cc } else { $null }
    Subject     = [string]$target.Subject
    Body        = [string]$target.Body
    ContentHash = [string]$target.ContentHash
    SentAt      = $now
    Status      = 'resent'
    From        = [string]$target.From
    SmtpServer  = [string]$target.SmtpServer
    KeyName     = [string]$target.KeyName
    Port        = $port
}
Add-SentEmailRecord -SentEmailsPath $matched.SentEmailsPath `
    -TaskName $TaskName -RunId $RunId -Cycle $cycleId -Email $resendRecord

Write-Host "Ledger and sent-emails.json updated with 'resent' status." -ForegroundColor Green
exit 0
