# Angular 19 升级验证清单

**适用场景：项目无 Unit Test / E2E Test，需通过手动方式验证升级是否成功**

---

## 目录

- [第一层：构建与编译验证](#第一层构建与编译验证)
- [第二层：运行时基础验证](#第二层运行时基础验证)
- [第三层：核心业务流程验证](#第三层核心业务流程验证)
- [第四层：UI 组件逐项验证](#第四层ui-组件逐项验证)
- [第五层：兼容性与边界验证](#第五层兼容性与边界验证)
- [第六层：版本与依赖确认](#第六层版本与依赖确认)
- [验证结果记录模板](#验证结果记录模板)

---

## 第一层：构建与编译验证

> 目标：确认代码能正确编译，无类型错误

### 1.1 Development 构建

```powershell
npm run build
```

| 检查项 | 预期结果 | 实际结果 |
|--------|---------|---------|
| 构建是否成功 | `Application bundle generation complete` | ☐ Pass ☐ Fail |
| 是否有 ERROR | 零 error | ☐ Pass ☐ Fail |
| WARNING 数量 | 记录数量，与升级前对比 | ____个 |

### 1.2 Production 构建

```powershell
npm run deploy
```

| 检查项 | 预期结果 | 实际结果 |
|--------|---------|---------|
| Prod 构建是否成功 | 无 error | ☐ Pass ☐ Fail |
| 产物输出路径 | `dist/cod-fd-ui` 目录存在 | ☐ Pass ☐ Fail |
| 产物体积 | 记录 Initial total 大小 | ____MB |

### 1.3 TypeScript 类型检查

```powershell
npx tsc --noEmit
```

| 检查项 | 预期结果 | 实际结果 |
|--------|---------|---------|
| 类型检查是否通过 | 零 error | ☐ Pass ☐ Fail |

---

## 第二层：运行时基础验证

> 目标：确认应用能正常启动、路由跳转、认证流程正常

### 2.1 应用启动

```powershell
npm start
```

| 检查项 | 预期结果 | 实际结果 |
|--------|---------|---------|
| 启动是否成功 | `Compiled successfully` | ☐ Pass ☐ Fail |
| 浏览器访问 `localhost:3600` | 页面正常加载，无白屏 | ☐ Pass ☐ Fail |
| 浏览器 Console 是否有 ERROR | 零红色 error（warning 可接受） | ☐ Pass ☐ Fail |

### 2.2 认证流程（OIDC）

| 检查项 | 操作步骤 | 预期结果 | 实际结果 |
|--------|---------|---------|---------|
| 登录跳转 | 访问受保护页面 | 自动跳转到登录页 | ☐ Pass ☐ Fail |
| 登录成功 | 输入凭证登录 | 跳转回应用，显示用户信息 | ☐ Pass ☐ Fail |
| Token 获取 | 打开 DevTools → Application → Session Storage | 能看到 access_token | ☐ Pass ☐ Fail |
| Token 注入 | 打开 DevTools → Network，查看 API 请求 | Header 中有 Authorization: Bearer xxx | ☐ Pass ☐ Fail |
| 登出 | 点击登出按钮 | 成功登出，跳转到登出页面 | ☐ Pass ☐ Fail |
| Token 过期刷新 | 等待 token 快过期或手动触发 | silent renew 正常工作 | ☐ Pass ☐ Fail |

### 2.3 路由导航

| 检查项 | 操作步骤 | 预期结果 | 实际结果 |
|--------|---------|---------|---------|
| 首页加载 | 访问根路由 `/` | 首页正常显示 | ☐ Pass ☐ Fail |
| 页面跳转 | 点击导航栏各菜单项 | 页面切换正常，无报错 | ☐ Pass ☐ Fail |
| URL 直接访问 | 浏览器直接输入子路由 URL | 页面正常加载 | ☐ Pass ☐ Fail |
| 404 处理 | 访问不存在的路由 | 显示 404 或 unauthorized 页面 | ☐ Pass ☐ Fail |
| 浏览器前进/后退 | 使用浏览器前进后退按钮 | 页面正确切换 | ☐ Pass ☐ Fail |

---

## 第三层：核心业务流程验证

> 目标：确认主要业务功能正常运行

### 3.1 数据加载（HTTP 请求）

| 检查项 | 操作步骤 | 预期结果 | 实际结果 |
|--------|---------|---------|---------|
| 列表加载 | 进入列表页面 | 数据正常显示 | ☐ Pass ☐ Fail |
| 搜索功能 | 输入关键词搜索 | 返回正确结果 | ☐ Pass ☐ Fail |
| 分页功能 | 点击翻页 | 数据正确切换 | ☐ Pass ☐ Fail |
| 排序功能 | 点击表头排序 | 排序结果正确 | ☐ Pass ☐ Fail |
| 筛选功能 | 使用筛选条件 | 筛选结果正确 | ☐ Pass ☐ Fail |

### 3.2 数据操作（CRUD）

| 检查项 | 操作步骤 | 预期结果 | 实际结果 |
|--------|---------|---------|---------|
| 新增 | 创建新记录 | 保存成功，列表刷新 | ☐ Pass ☐ Fail |
| 查看 | 点击查看详情 | 详情页正确显示 | ☐ Pass ☐ Fail |
| 编辑 | 修改记录并保存 | 修改成功，数据更新 | ☐ Pass ☐ Fail |
| 删除 | 删除记录 | 删除成功，列表刷新 | ☐ Pass ☐ Fail |

### 3.3 表单验证

| 检查项 | 操作步骤 | 预期结果 | 实际结果 |
|--------|---------|---------|---------|
| 必填校验 | 不填必填项，点提交 | 显示错误提示，阻止提交 | ☐ Pass ☐ Fail |
| 格式校验 | 输入错误格式（如邮箱） | 显示格式错误提示 | ☐ Pass ☐ Fail |
| 正常提交 | 填写完整后提交 | 提交成功 | ☐ Pass ☐ Fail |

### 3.4 文件操作

| 检查项 | 操作步骤 | 预期结果 | 实际结果 |
|--------|---------|---------|---------|
| Excel 导出 | 点击导出按钮 | 下载 .xlsx 文件，内容正确 | ☐ Pass ☐ Fail |
| 文件上传 | 上传文件 | 上传成功，文件处理正确 | ☐ Pass ☐ Fail |
| 打印功能 | 使用 print 功能 | 打印预览正常 | ☐ Pass ☐ Fail |

---

## 第四层：UI 组件逐项验证

> 目标：确认升级后第三方 UI 组件样式和行为正常

### 4.1 ngx-bootstrap 组件

| 组件 | 操作步骤 | 预期结果 | 实际结果 |
|------|---------|---------|---------|
| Modal 弹窗 | 触发弹窗打开 | 弹窗居中显示，遮罩层正常 | ☐ Pass ☐ Fail |
| Modal 关闭 | 点击关闭/遮罩/ESC | 弹窗正常关闭 | ☐ Pass ☐ Fail |
| Dropdown | 点击下拉按钮 | 菜单正常展开/收起 | ☐ Pass ☐ Fail |
| Tooltip | 悬停在带提示的元素 | 提示框正确定位显示 | ☐ Pass ☐ Fail |
| Datepicker | 点击日期选择器 | 日历正常弹出，选择日期正常 | ☐ Pass ☐ Fail |
| Accordion | 点击折叠面板 | 展开/收起动画正常 | ☐ Pass ☐ Fail |
| Tab | 点击标签页 | 切换内容正常 | ☐ Pass ☐ Fail |

### 4.2 ng-bootstrap 组件

| 组件 | 操作步骤 | 预期结果 | 实际结果 |
|------|---------|---------|---------|
| Typeahead | 输入文字 | 自动补全建议正常显示 | ☐ Pass ☐ Fail |
| Pagination | 翻页 | 页码切换正常 | ☐ Pass ☐ Fail |
| Alert | 触发告警 | 告警样式正常 | ☐ Pass ☐ Fail |

### 4.3 Angular Material 组件

| 组件 | 操作步骤 | 预期结果 | 实际结果 |
|------|---------|---------|---------|
| Table | 查看数据表格 | 表格渲染正常 | ☐ Pass ☐ Fail |
| Dialog | 打开 Material 对话框 | 对话框样式和行为正常 | ☐ Pass ☐ Fail |
| Form Field | 查看输入框 | 浮动标签/下划线样式正常 | ☐ Pass ☐ Fail |
| Select | 下拉选择 | 选项列表正常显示 | ☐ Pass ☐ Fail |
| Snackbar | 触发消息提示 | 底部消息条正常显示 | ☐ Pass ☐ Fail |

### 4.4 导航栏和布局

| 检查项 | 预期结果 | 实际结果 |
|--------|---------|---------|
| 顶部导航栏 | 样式正常，菜单可点击 | ☐ Pass ☐ Fail |
| 侧边栏（如有） | 展开/收起正常 | ☐ Pass ☐ Fail |
| 响应式布局 | 缩小窗口，布局自适应 | ☐ Pass ☐ Fail |
| 页面整体样式 | 字体、颜色、间距无异常 | ☐ Pass ☐ Fail |

---

## 第五层：兼容性与边界验证

> 目标：确认边界情况和跨浏览器兼容性

### 5.1 浏览器兼容

| 浏览器 | 版本 | 页面加载 | 核心功能 | 实际结果 |
|--------|------|---------|---------|---------|
| Chrome | 最新版 | ☐ 正常 | ☐ 正常 | ☐ Pass ☐ Fail |
| Edge | 最新版 | ☐ 正常 | ☐ 正常 | ☐ Pass ☐ Fail |
| Firefox | 最新版（如需支持） | ☐ 正常 | ☐ 正常 | ☐ Pass ☐ Fail |

### 5.2 DevTools Console 检查

在每个主要页面打开浏览器 DevTools Console，记录：

| 页面 | 红色 Error 数量 | 黄色 Warning 数量 | 备注 |
|------|---------------|-----------------|------|
| 首页 | | | |
| 搜索页 | | | |
| 详情页 | | | |
| 表单页 | | | |
| 设置页 | | | |

> ⚠️ 升级后常见的可接受 warning：
> - `Polyfill for "@angular/localize/init" was added automatically` — 已通过 `main.ts` import 修复
> - `Module 'file-saver' is not ESM` — CommonJS 兼容提示，不影响功能
> - Angular DevMode 相关的 warning — 仅开发模式出现

### 5.3 Network 请求检查

打开 DevTools → Network，操作主要功能：

| 检查项 | 预期结果 | 实际结果 |
|--------|---------|---------|
| API 请求状态码 | 200/201，无异常 4xx/5xx | ☐ Pass ☐ Fail |
| 请求 Header | Authorization Bearer token 存在 | ☐ Pass ☐ Fail |
| 响应数据 | JSON 数据结构正确 | ☐ Pass ☐ Fail |
| 无多余请求 | 没有重复/死循环请求 | ☐ Pass ☐ Fail |

### 5.4 性能基线对比

| 指标 | 升级前 | 升级后 | 差异 |
|------|--------|--------|------|
| Build 时间 | ____秒 | ____秒 | |
| Bundle 体积（Initial total） | ____MB | ____MB | |
| 首页加载时间（DevTools） | ____秒 | ____秒 | |

---

## 第六层：版本与依赖确认

> 目标：确认所有包版本正确对齐

### 6.1 Angular 版本确认

```powershell
ng version
```

| 包 | 预期版本 | 实际版本 | 状态 |
|---|---------|---------|------|
| Angular CLI | 19.2.x | | ☐ 正确 |
| Angular Core | 19.2.x | | ☐ 正确 |
| Angular Material | 19.2.x | | ☐ 正确 |
| TypeScript | 5.6.x | | ☐ 正确 |
| zone.js | 0.15.x | | ☐ 正确 |
| RxJS | 7.8.x | | ☐ 正确 |

### 6.2 第三方包版本确认

```powershell
npm ls @ng-bootstrap/ng-bootstrap ngx-bootstrap angular-auth-oidc-client
```

| 包 | 预期版本 | 实际版本 | 状态 |
|---|---------|---------|------|
| `@ng-bootstrap/ng-bootstrap` | 18.x | | ☐ 正确 |
| `ngx-bootstrap` | 19.x | | ☐ 正确 |
| `angular-auth-oidc-client` | 19.x | | ☐ 正确 |

### 6.3 esbuild 配置确认

```powershell
findstr "esbuild" package.json
```

| 检查项 | 预期值 | 实际值 | 状态 |
|--------|--------|--------|------|
| overrides.esbuild | 0.25.12 | | ☐ 正确 |

### 6.4 localize 配置确认

```powershell
findstr "localize" src\main.ts
```

| 检查项 | 预期值 | 状态 |
|--------|--------|------|
| `main.ts` 第一行有 `import '@angular/localize/init'` | 存在 | ☐ 正确 |

---

## 验证结果记录模板

```
验证日期：____年____月____日
验证人员：________________
升级分支：upgrade/angular-19

=== 构建验证 ===
Dev Build:     ☐ Pass  ☐ Fail
Prod Build:    ☐ Pass  ☐ Fail
TypeScript:    ☐ Pass  ☐ Fail

=== 运行时验证 ===
应用启动:      ☐ Pass  ☐ Fail
登录流程:      ☐ Pass  ☐ Fail
路由导航:      ☐ Pass  ☐ Fail

=== 业务功能验证 ===
数据加载:      ☐ Pass  ☐ Fail
CRUD 操作:     ☐ Pass  ☐ Fail
表单验证:      ☐ Pass  ☐ Fail
文件操作:      ☐ Pass  ☐ Fail

=== UI 组件验证 ===
ngx-bootstrap: ☐ Pass  ☐ Fail
ng-bootstrap:  ☐ Pass  ☐ Fail
Material:      ☐ Pass  ☐ Fail
导航布局:      ☐ Pass  ☐ Fail

=== 兼容性验证 ===
Chrome:        ☐ Pass  ☐ Fail
Edge:          ☐ Pass  ☐ Fail
Console Error: ☐ 零    ☐ 有（____个）

=== 版本确认 ===
Angular Core:  ☐ 19.2.x
Material:      ☐ 19.2.x
TypeScript:    ☐ 5.6.x

=== 最终结论 ===
☐ 升级验证通过，可以创建 PR 合并
☐ 升级验证未通过，需修复以下问题：
  1. ____________________
  2. ____________________
  3. ____________________

签字：________________  日期：________________
```

---

*验证完成后，将此文档填写完整，作为升级 PR 的附件提交，供团队 review。*