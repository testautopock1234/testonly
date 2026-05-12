<span class="tooltip-text no-texting-link"
      [ngbPopover]="noTextingAlertTpl"
      popoverClass="no-texting-popover"
      placement="top-start top top-end bottom-start auto"
      triggers="mouseenter:mouseleave"
      container="body">
  (No Texting)
</span>

<ng-template #noTextingAlertTpl>
  <div class="no-texting-alert">
    <i class="bi bi-exclamation-triangle no-texting-alert-icon" aria-hidden="true"></i>

    <div class="no-texting-alert-content">
      <div class="no-texting-alert-title">ALERT</div>
      <ul class="no-texting-alert-list">
        <li>Do not send a business text to a colleague's personal mobile phone.</li>
        <li>
          For more information please review the
          <a target="_blank"
             href="https://abctestchina.sharepoint.cn/sites/howto/SitePages/Firm-Approved-Communications.aspx">
            Communications Guidance FAQs
          </a>
        </li>
      </ul>
    </div>
  </div>
</ng-template>
