# Angular v17 → v18 → v19 升级全程实操记录

**项目：cod-fd-ui　|　操作日期：2026-04-09　|　操作系统：Windows (PowerShell)**

> 本文档记录了从 Angular 17.3.x 升级到 19.2.x 的**完整实际操作过程**，
> 包含每一步的命令、遇到的问题、以及最终的解决方案。

---

## 目录

- [起始状态](#起始状态)
- [Phase 0 — 升级前准备](#phase-0--升级前准备)
- [Phase 1 — Angular 17 → 18（由其他团队成员完成）](#phase-1--angular-17--18由其他团队成员完成)
- [Phase 1.5 — v18 依赖对齐修复](#phase-15--v18-依赖对齐修复)
- [Phase 2 — Angular 18 → 19](#phase-2--angular-18--19)
- [Phase 2.5 — 运行时问题修复](#phase-25--运行时问题修复)
- [Phase 3 — 最终验证与提交](#phase-3--最终验证与提交)
- [最终版本对照表](#最终版本对照表)
- [踩坑汇总与解决方案](#踩坑汇总与解决方案)

---

## 起始状态

### 原始 package.json 关键版本

| 包名 | 原始版本 |
|------|---------|
| `@angular/core` | ^17.3.0 |
| `@angular/material` | ^17.3.10 |
| `@angular-devkit/build-angular` | ^17.3.4 |
| `@angular/cli` | ^17.3.4 |
| `@ng-bootstrap/ng-bootstrap` | ^16.0.0 |
| `ngx-bootstrap` | ^12.0.0 |
| `angular-auth-oidc-client` | 18.0.2 |
| `zone.js` | ~0.14.3 |
| `typescript` | ~5.4.2 |
| `rxjs` | ~7.8.0 |
| `esbuild` (overrides) | 0.25.5 |

### 环境

| 项目 | 版本 |
|------|------|
| Node.js | 20.19.4 |
| npm | 10.8.2 |
| 私有 npm 源 | artifactory.ai.ms.com.cn |

---

## Phase 0 — 升级前准备

### 0.1 创建升级分支

```powershell
git checkout -b upgrade/angular-19
git push -u origin upgrade/angular-19
```

### 0.2 清理依赖缓存

```powershell
Remove-Item -Recurse -Force node_modules
Remove-Item package-lock.json
npm cache clean --force
```

### 0.3 确认环境

```powershell
node -v       # v20.19.4 ✅
npm -v        # 10.8.2 ✅
ng version    # 17.3.x ✅
```

---

## Phase 1 — Angular 17 → 18（由其他团队成员完成）

> 此阶段在 review 时发现有遗漏项，记录实际结果和问题。

### 1.1 Angular 核心升级

```powershell
ng update @angular/core@18 @angular/cli@18 --force
```

**结果**：Angular 核心包升级到 ^18.2.14 ✅

### 1.2 Angular Material 升级

```powershell
ng update @angular/material@18
```

**结果**：Material 升级到 ^18.2.14 ✅

### 1.3 第三方包升级

```powershell
npm install @ng-bootstrap/ng-bootstrap@17
npm install ngx-bootstrap@18
```

**结果**：
- `@ng-bootstrap/ng-bootstrap` → ^17.0.0 ✅
- `ngx-bootstrap` → ^18.0.0 ✅

### 1.4 v18 阶段 Review 发现的遗漏

对照升级手册检查 v18 完成后的 package.json，发现以下 4 项未正确处理：

| 包名 | 实际版本 | 应该版本 | 状态 |
|------|---------|---------|------|
| `angular-auth-oidc-client` | 18.0.2 | **19.x** | ❌ 未升级 |
| `zone.js` | ~0.14.3 | **~0.14.10** | ❌ 未升级 |
| `typescript` | ~5.4.5 | **~5.5.0** | ❌ 未升级 |
| `esbuild` (overrides) | 0.25.5 | **应评估** | ⚠️ 需处理 |
| `is-arrayish` (overrides) | 0.3.4 | — | ✅ 新增的冲突修复，保留 |

> ⚠️ 关键说明：`angular-auth-oidc-client` 的版本号与 Angular 版本不是一一对应。
> Angular 17 对应 v18，Angular 18 对应 **v19**，Angular 19 也继续使用 **v19**。
> v20 要求 `@angular/common@>=20.0.0`，与 Angular 19 不兼容。

---

## Phase 1.5 — v18 依赖对齐修复

### 1.5.1 升级 angular-auth-oidc-client

```powershell
npm install angular-auth-oidc-client@19
```

**结果**：`changed 1 package` ✅
**npm audit**：46 vulnerabilities（暂不处理，避免干扰升级）

### 1.5.2 升级 zone.js

```powershell
npm install zone.js@~0.14.10
```

**结果**：安装成功 ✅

### 1.5.3 升级 TypeScript

```powershell
npm install typescript@~5.5.0
```

**结果**：安装成功 ✅（有 EPERM cleanup warning，不影响）

### 1.5.4 esbuild overrides 处理

**最初尝试**：移除 esbuild override → `npm install` 失败

**报错**：
```
Failed to find package "@esbuild/win32-x64" on the file system
npm error 403 Forbidden - GET https://artifactory.ai.ms.com.cn/.../win32-x64-0.23.0.tgz
```

**根因分析**：
- 私有 npm 源上 `@esbuild/win32-x64@0.23.0` 返回 403
- esbuild 主包存在，但平台二进制包被禁止下载
- 外网 `registry.npmjs.org` 也无法访问（`ENOTFOUND`）

**最终决定**：保留 esbuild overrides 为 `0.25.5`，v18 阶段先不改动

```json
"overrides": {
  "esbuild": "0.25.5",
  "is-arrayish": "0.3.4"
}
```

### 1.5.5 清理重装并验证构建

```powershell
Remove-Item -Recurse -Force node_modules
Remove-Item package-lock.json
npm cache clean --force
npm install
npm run build
```

**Build 结果**：✅ 成功（11.889 seconds）

**Build Warnings**（均不阻塞）：
1. `Polyfill for "@angular/localize/init" was added automatically` — 后续需处理
2. `Bundle initial exceeded maximum budget` — 1.72MB 超出 1.57MB 预算
3. `Module 'file-saver' is not ESM` — CommonJS 兼容提示
4. `1 rules skipped due to selector errors` — Bootstrap CSS 解析器差异

### 1.5.6 提交 v18 阶段成果

```powershell
git add .
git commit -m "chore: upgrade angular to v18 and align dependencies"
```

**注意**：`git add .` 时出现 LF/CRLF warning，不影响功能，直接继续。

---

## Phase 2 — Angular 18 → 19

### 2.1 升级 Angular 核心

```powershell
ng update @angular/core@19 @angular/cli@19 --force
```

**执行过程中出现两个可选迁移提示：**

**提示 1：`[use-application-builder]` — 迁移到新构建系统**
- 操作：按**空格键**取消选中 → 按**回车键**跳过
- 原因：新构建系统变更大，不宜与版本升级同时进行

**提示 2：`[provide-initializer]` — 迁移 APP_INITIALIZER**
- 操作：按**空格键**取消选中 → 按**回车键**跳过
- 原因：旧写法仍支持，可后续单独迁移

**自动迁移结果**：
- 23 个文件被自动更新（standalone components 相关变更）
- `ExperimentalPendingTasks → PendingTasks`：No changes made
- `BootstrapContext → bootstrapApplication`：No changes made
- `provide-initializer`：No changes made
- `zone.js` 自动升级到 0.15.1

**Angular 核心升级版本**：
- `@angular/core` → 19.2.20
- `@angular/cli` → 19.2.23
- `@angular-devkit/build-angular` → 19.2.23

### 2.2 提交核心升级

```powershell
git add .
git commit -m "chore: upgrade angular core to v19"
```

> `ng update @angular/material` 要求 Git 工作区干净，必须先提交。

### 2.3 升级 Angular Material

```powershell
ng update @angular/material@19
```

**结果**：大量文件被自动迁移（Material 组件 import 路径、API 变更、standalone component 调整），属正常行为。

```powershell
git add .
git commit -m "chore: upgrade angular material to v19"
```

### 2.4 升级 @angular/localize

```powershell
npm install @angular/localize@19 --legacy-peer-deps
```

**为什么需要这步**：`ng update` 没有自动升级 `@angular/localize`，停留在 18.2.14，导致后续安装第三方包时 peer dependency 冲突。

**结果**：`removed 15 packages, changed 3 packages` ✅

### 2.5 升级第三方包

**第一次尝试**：逐个安装

```powershell
npm install @ng-bootstrap/ng-bootstrap@18
```

**报错**：`ERESOLVE` — `ngx-bootstrap@18.1.3` 要求 `@angular/animations@^18.0.1`，与 Angular 19 冲突。

**第二次尝试**：先升级 ngx-bootstrap

```powershell
npm install ngx-bootstrap@19
```

**报错**：`ERESOLVE` — `@angular/localize@18.2.14` 冲突（此时 localize 还未升级，后来先执行了 2.4 步骤解决）。

**第三次尝试**：安装 `angular-auth-oidc-client@20`

```powershell
npm install angular-auth-oidc-client@20
```

**报错**：`ERESOLVE` — v20.0.3 要求 `@angular/common@>=20.0.0`，与 Angular 19 不兼容。

**验证版本兼容性**：

```powershell
npm view angular-auth-oidc-client versions --json
```

确认：v20 是给 Angular 20 用的，Angular 19 应继续使用 **v19**。

**最终成功的命令**（在 localize 已升级到 v19 之后）：

```powershell
npm install ngx-bootstrap@19 @ng-bootstrap/ng-bootstrap@18 angular-auth-oidc-client@19 typescript@~5.6.0 --legacy-peer-deps
```

**结果**：`added 11 packages, changed 3 packages` ✅

### 2.6 esbuild overrides 处理

**问题**：清理 `node_modules` 后 `npm install` 报错

```
Failed to find package "@esbuild/win32-x64" on the file system
npm error 403 Forbidden - @esbuild/win32-x64@0.25.5
```

**分析过程**：

1. 查看 Angular 19 的 esbuild 依赖：
   ```powershell
   npm view @angular-devkit/build-angular@19.2.23 dependencies --json
   ```
   发现 Angular 19 依赖 `esbuild-wasm: "0.25.4"`（不是原生 esbuild）

2. 查看私有源上 `@esbuild/win32-x64` 可用版本：
   - Artifactory 页面显示有该包，最新 0.27.7
   - 但 0.25.5 版本被 403 Forbidden

3. 尝试 **esbuild-wasm 替代方案**：
   ```json
   "overrides": { "esbuild": "npm:esbuild-wasm@0.25.4" }
   ```
   `npm install` 成功，但 `npm run build` / `npm start` 报错：
   ```
   The working directory "C:\Users\guling\workspace\ui" is not an absolute path
   ```
   **原因**：esbuild-wasm 在 Windows 上无法正确处理 Windows 路径格式，这是已知 bug。

4. **最终方案**：使用私有源上有的原生 esbuild 版本

   确认私有源上 `@esbuild/win32-x64@0.25.12` 可用：

   ```json
   "overrides": {
     "esbuild": "0.25.12",
     "is-arrayish": "0.3.4"
   }
   ```

   > 0.25.5 → 0.25.12 是 patch 版本升级，只有 bugfix 没有 breaking change，
   > 与 Angular 19 完全兼容。同时 0.25.12 解决了 0.25.5 之前的 CVE 问题
   > （CVE-2024-23334 影响 ≤0.24.2，0.25.x 均已修复）。

### 2.7 清理重装并验证构建

```powershell
Remove-Item -Recurse -Force node_modules
Remove-Item package-lock.json
npm cache clean --force
npm install
npm run build
```

**结果**：✅ 构建成功

---

## Phase 2.5 — 运行时问题修复

### 2.5.1 `$localize is not defined` 错误

**现象**：`npm start` 后应用可以启动，但执行搜索等操作时浏览器 Console 报错：

```
ERROR ReferenceError: $localize is not defined
```

**分析**：
- `@angular/localize` 已安装（19.2.20）
- Build 时有 warning：`Polyfill for "@angular/localize/init" was added automatically`
- 说明构建时自动注入了，但运行时没有正确加载

**尝试 1**：在 `angular.json` 的 polyfills 数组中添加 `"@angular/localize/init"`

```json
"polyfills": [
  "@angular/localize/init",
  "zone.js"
]
```

**结果**：`npm run build` 报错 `Could not resolve "@angular/localize/init"`

**原因**：项目使用旧的 `browser` builder，polyfills 的 resolve 方式与 `application` builder 不同。

**尝试 2（最终方案）**：在 `src/main.ts` 文件最顶部添加 import

```typescript
import '@angular/localize/init';  // ← 必须是文件第一行

// ... 其他原有 import
```

同时将 `angular.json` 的 polyfills 改回原样：

```json
"polyfills": [
  "zone.js"
]
```

**结果**：✅ `$localize` 错误消失，应用正常运行

---

## Phase 3 — 最终验证与提交

### 3.1 构建验证

```powershell
npm run build    # ✅ 成功
npm run deploy   # ✅ Production 构建成功
npm start        # ✅ 应用正常启动，功能正常
```

### 3.2 提交

```powershell
git add .
git commit -m "chore: upgrade angular to v19 with all dependencies"
```

> `package-lock.json` 必须一起提交，确保团队成员和 CI/CD 安装到一致的依赖版本。

---

## 最终版本对照表

| 包名 | v17 原始版本 | v18 阶段 | v19 最终 |
|------|------------|---------|---------|
| `@angular/core` | ^17.3.0 | ^18.2.14 | ^19.2.20 |
| `@angular/material` | ^17.3.10 | ^18.2.14 | ^19.2.19 |
| `@angular/localize` | — | ^18.2.14 | ^19.2.20 |
| `@angular-devkit/build-angular` | ^17.3.4 | ^18.2.21 | ^19.2.23 |
| `@angular/cli` | ^17.3.4 | ^18.2.21 | ^19.2.23 |
| `@angular/compiler-cli` | ^17.3.0 | ^18.2.14 | ^19.2.20 |
| `@ng-bootstrap/ng-bootstrap` | ^16.0.0 | ^17.0.0 | ^18.x |
| `ngx-bootstrap` | ^12.0.0 | ^18.0.0 | ^19.x |
| `angular-auth-oidc-client` | 18.0.2 | 19.x | 19.x |
| `zone.js` | ~0.14.3 | ~0.14.10 | ~0.15.1 |
| `typescript` | ~5.4.2 | ~5.5.0 | ~5.6.0 |
| `rxjs` | ~7.8.0 | ~7.8.0 | ~7.8.0 |
| `esbuild` (overrides) | 0.25.5 | 0.25.5 | **0.25.12** |

### 特殊配置

| 配置项 | 位置 | 值 | 说明 |
|--------|------|-----|------|
| esbuild override | `package.json` overrides | `"esbuild": "0.25.12"` | 私有源上 0.25.5 的平台包被 403，改用 0.25.12 |
| is-arrayish override | `package.json` overrides | `"is-arrayish": "0.3.4"` | 依赖冲突修复，保留 |
| localize polyfill | `src/main.ts` 第一行 | `import '@angular/localize/init'` | angular.json polyfills 无法 resolve，改为 main.ts import |

---

## 踩坑汇总与解决方案

### 踩坑 1：angular-auth-oidc-client 版本对应关系

| 问题 | `angular-auth-oidc-client` v20 要求 `@angular/common@>=20.0.0` |
|------|---------------------------------------------------------------|
| 原因 | 该库版本号与 Angular 版本不是一一对应，v20 是给 Angular 20 用的 |
| 解决 | Angular 18 和 Angular 19 都使用 `angular-auth-oidc-client@19` |
| 验证命令 | `npm view angular-auth-oidc-client versions --json` |

### 踩坑 2：esbuild 平台包 403 Forbidden

| 问题 | `npm install` 报 `Failed to find package "@esbuild/win32-x64"` 403 |
|------|-------------------------------------------------------------------|
| 原因 | 私有 npm 源上 `@esbuild/win32-x64@0.25.5` 不可用 |
| 排查 | Artifactory UI 查看可用版本，发现 0.25.12 可用 |
| 解决 | `"overrides": { "esbuild": "0.25.12" }` |
| 备注 | 0.25.x patch 版本间向后兼容，不影响 Angular 19 |

### 踩坑 3：esbuild-wasm Windows 路径不兼容

| 问题 | 使用 `npm:esbuild-wasm@0.25.4` 后报 `is not an absolute path` |
|------|-------------------------------------------------------------|
| 原因 | esbuild-wasm 无法正确处理 Windows 路径格式（`C:\...`），这是已知 bug |
| 解决 | 放弃 esbuild-wasm 方案，改用原生 esbuild 0.25.12 |
| 教训 | Windows 环境不能使用 esbuild-wasm 替代原生 esbuild |

### 踩坑 4：@angular/localize 未随 ng update 自动升级

| 问题 | 安装第三方包时报 `@angular/localize@18.2.14` peer dependency 冲突 |
|------|---------------------------------------------------------------|
| 原因 | `ng update @angular/core@19` 没有自动升级 `@angular/localize` |
| 解决 | `npm install @angular/localize@19 --legacy-peer-deps` |
| 教训 | `ng update` 后需检查所有 `@angular/*` 包是否一致 |

### 踩坑 5：$localize is not defined 运行时错误

| 问题 | 应用运行时浏览器报 `ReferenceError: $localize is not defined` |
|------|-----------------------------------------------------------|
| 原因 | `angular.json` 的 polyfills 配置无法 resolve `@angular/localize/init`（browser builder 限制）|
| 尝试 | 在 `angular.json` polyfills 中添加 → build 报 `Could not resolve` |
| 解决 | 在 `src/main.ts` 第一行添加 `import '@angular/localize/init'` |
| 教训 | 使用旧 browser builder 的项目，localize polyfill 需通过 main.ts import |

### 踩坑 6：ng update 要求 Git 工作区干净

| 问题 | `ng update @angular/material@19` 报 `Repository is not clean` |
|------|-------------------------------------------------------------|
| 原因 | `ng update` 执行前要求所有变更已提交 |
| 解决 | 每次 `ng update` 前先 `git add . && git commit` |
| 教训 | 养成每个升级步骤后立即 commit 的习惯 |

### 踩坑 7：npm EPERM 文件锁（Windows）

| 问题 | `npm install` 报 `EPERM: operation not permitted, rmdir` |
|------|-------------------------------------------------------|
| 原因 | VS Code、ng serve 等进程占用 node_modules 内文件 |
| 解决 | 关闭所有占用进程，重新打开 PowerShell |
| 备注 | 大多数情况下只是 warning，不影响安装结果 |

### 踩坑 8：npm vulnerabilities 干扰升级

| 问题 | `npm install` 后显示 46 vulnerabilities |
|------|---------------------------------------|
| 原因 | 升级前就已存在 |
| 解决 | **升级过程中不处理**，`npm audit fix --force` 会打乱版本对齐 |
| 时机 | 等全部升级完成、build/test 稳定后再统一处理 |

---

## Git 提交历史

以下是整个升级过程中的 commit 记录（按时间顺序）：

```
1. chore: ng update angular core to v18
2. chore: upgrade angular to v18 and align dependencies
3. chore: upgrade angular core to v19
4. chore: upgrade angular material to v19
5. chore: upgrade angular to v19 with all dependencies
```

> 每个 commit 对应一个可独立回退的节点，回退粒度足够细。

---

## 后续待办

以下任务在升级完成后按优先级逐步处理（详见 `angular_v19_post_upgrade_migration_guide.md`）：

- [ ] 迁移 `HttpClientModule` → `provideHttpClient()`（高优先级）
- [ ] 迁移 `AuthModule.forRoot()` → `provideAuth()`（高优先级）
- [ ] 控制流语法迁移 `*ngIf/*ngFor` → `@if/@for`（中优先级）
- [ ] 移除 `ComponentFactoryResolver`（中优先级）
- [ ] UI 回归测试（必须）
- [ ] npm 漏洞统一处理（收尾）
- [ ] 评估切换到 `application` builder（长期）
- [ ] 联系 DevOps 同步 `@esbuild/win32-x64` 到私有源（长期优化）

---

*文档版本：v1.0　|　最后更新：2026-04-09*