# Angular 19 升级后收尾 — 破坏性变更手动迁移指南

**适用于：Angular 19.2.x　|　项目：**testonly

> 本文档为 Angular v17 → v19 升级完成后的收尾工作指南。
> 以下迁移项按优先级排列，建议每完成一项后单独提交并验证。

---

## 目录

- [Task 1 — HttpClientModule → provideHttpClient()](#task-1--httpclientmodule--providehttpclient)（高优先级）
- [Task 2 — AuthModule.forRoot() → provideAuth()](#task-2--authmoduleforroot--provideauth)（高优先级）
- [Task 3 — 控制流语法迁移](#task-3--控制流语法迁移)（中优先级）
- [Task 4 — ComponentFactoryResolver 移除](#task-4--componentfactoryresolver-移除)（中优先级）
- [Task 5 — RouterModule.forRoot() → provideRouter()](#task-5--routermoduleforroot--providerouter)（低优先级）
- [Task 6 — APP_INITIALIZER → provideAppInitializer()](#task-6--app_initializer--provideappinitializer)（低优先级）
- [Task 7 — UI 回归测试](#task-7--ui-回归测试)（必须）
- [Task 8 — npm 漏洞处理](#task-8--npm-漏洞处理)（收尾）
- [附录 A — 每次迁移的标准验证流程](#附录-a--每次迁移的标准验证流程)

---

## 通用规则

1. **每个 Task 独立一个 commit**，方便回退
2. 每个 Task 完成后执行[标准验证流程](#附录-a--每次迁移的标准验证流程)
3. 如遇编译错误，先排查再继续下一个 Task
4. 所有修改在 `upgrade/angular-19` 分支进行

---

## Task 1 — HttpClientModule → provideHttpClient()

**优先级：高　|　风险：低　|　影响范围：HTTP 请求和拦截器**

Angular 18 起 `HttpClientModule` 已被标记为 deprecated，Angular 19 仍可用但建议尽快迁移。

### Step 1.1 — 搜索所有 HttpClientModule 用法

```powershell
findstr /s /i "HttpClientModule" src\app\*.ts src\app\*.module.ts
```

记录所有出现的文件，通常在：
- `app.module.ts`（主模块）
- 其他 feature module 文件

### Step 1.2 — 修改主模块 `app.module.ts`

**修改前：**

```typescript
import { HttpClientModule } from '@angular/common/http';

@NgModule({
  imports: [
    BrowserModule,
    HttpClientModule,
    // ... 其他 imports
  ],
  providers: [
    { provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true },
    // ... 其他 providers
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
```

**修改后：**

```typescript
// 1. 移除 HttpClientModule 的 import
// import { HttpClientModule } from '@angular/common/http';  // ← 删除这行

// 2. 新增 provideHttpClient 和 withInterceptorsFromDi 的 import
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';

@NgModule({
  imports: [
    BrowserModule,
    // HttpClientModule,  // ← 从 imports 数组中删除
    // ... 其他 imports
  ],
  providers: [
    provideHttpClient(withInterceptorsFromDi()),  // ← 新增这行
    { provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true },
    // ... 其他 providers
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
```

> ⚠️ **关键说明**：
> - `withInterceptorsFromDi()` 是必须的，它确保现有的 class-based HTTP 拦截器（如 `AuthInterceptor`）继续正常工作
> - 如果项目中没有使用 `HTTP_INTERCEPTORS`，可以简化为 `provideHttpClient()`
> - `{ provide: HTTP_INTERCEPTORS, ... }` 的配置保持不变，无需修改拦截器代码

### Step 1.3 — 处理 feature module 中的 HttpClientModule

如果其他 module 也 import 了 `HttpClientModule`，**直接移除即可**，不需要在每个子模块中都调用 `provideHttpClient()`。只需要在根模块配置一次。

```typescript
// feature.module.ts — 移除 HttpClientModule
@NgModule({
  imports: [
    CommonModule,
    // HttpClientModule,  // ← 删除这行，根模块已配置
  ],
})
export class FeatureModule { }
```

### Step 1.4 — 确认无遗漏

```powershell
findstr /s /i "HttpClientModule" src\app\*.ts
```

应该返回 **零结果**（或只有注释）。

### Step 1.5 — 验证并提交

```powershell
npm run build
npm start
```

手动测试几个涉及 HTTP 请求的页面，确认数据加载正常、拦截器（如 auth token 注入）正常工作。

```powershell
git add .
git commit -m "refactor: migrate HttpClientModule to provideHttpClient()"
```

---

## Task 2 — AuthModule.forRoot() → provideAuth()

**优先级：高　|　风险：中　|　影响范围：OIDC 认证流程**

`angular-auth-oidc-client` v19 同时支持 `AuthModule.forRoot()` 和 `provideAuth()`，但新写法是推荐方式。

### Step 2.1 — 搜索当前 OIDC 配置

```powershell
findstr /s /i "AuthModule" src\app\*.ts src\app\*.module.ts
```

```powershell
findstr /s /i "forRoot" src\app\*.ts src\app\*.module.ts
```

找到 OIDC 配置所在文件，通常是 `app.module.ts` 或独立的 `auth-config.module.ts`。

### Step 2.2 — 记录当前配置参数

在修改前，先完整记录现有配置参数，例如：

```typescript
// 当前配置（记录下来备用）
AuthModule.forRoot({
  config: {
    authority: 'https://your-identity-server.com',
    redirectUrl: window.location.origin,
    postLogoutRedirectUri: window.location.origin,
    clientId: 'your-client-id',
    scope: 'openid profile email',
    responseType: 'code',
    silentRenew: true,
    useRefreshToken: true,
    // ... 其他配置项
  }
})
```

### Step 2.3 — 迁移到 provideAuth()

**修改前（app.module.ts 或 auth-config.module.ts）：**

```typescript
import { AuthModule } from 'angular-auth-oidc-client';

@NgModule({
  imports: [
    AuthModule.forRoot({
      config: {
        authority: 'https://your-identity-server.com',
        redirectUrl: window.location.origin,
        postLogoutRedirectUri: window.location.origin,
        clientId: 'your-client-id',
        scope: 'openid profile email',
        responseType: 'code',
        silentRenew: true,
        useRefreshToken: true,
      }
    }),
  ],
})
```

**修改后（app.module.ts）：**

```typescript
// 1. 移除 AuthModule 的 import（如果只用于 forRoot）
// 2. 新增 provideAuth 的 import
import { provideAuth } from 'angular-auth-oidc-client';

@NgModule({
  imports: [
    // AuthModule.forRoot({...}),  // ← 从 imports 中移除
  ],
  providers: [
    // ← 将配置移到 providers 中
    provideAuth({
      config: {
        authority: 'https://your-identity-server.com',
        redirectUrl: window.location.origin,
        postLogoutRedirectUri: window.location.origin,
        clientId: 'your-client-id',
        scope: 'openid profile email',
        responseType: 'code',
        silentRenew: true,
        useRefreshToken: true,
      }
    }),
  ],
})
```

### Step 2.4 — 如果有独立的 AuthConfigModule

如果 OIDC 配置在单独的 module 文件中（如 `auth-config.module.ts`），有两种处理方式：

**方式 A — 将配置移到 app.module.ts 的 providers 中**（推荐）

删除 `auth-config.module.ts`，将 `provideAuth()` 放到 `app.module.ts` 的 providers 中。同时从 `app.module.ts` 的 imports 中移除 `AuthConfigModule`。

**方式 B — 保留独立文件但改为 provider 函数**

```typescript
// auth-config.ts（不再是 module，改为导出 provider）
import { provideAuth } from 'angular-auth-oidc-client';

export const authProviders = provideAuth({
  config: {
    authority: 'https://your-identity-server.com',
    // ... 完整配置
  }
});
```

```typescript
// app.module.ts
import { authProviders } from './auth-config';

@NgModule({
  providers: [
    authProviders,
  ],
})
```

### Step 2.5 — 检查 AuthInterceptor 注册方式

搜索项目中 `AuthInterceptor` 的注册方式：

```powershell
findstr /s /i "AuthInterceptor" src\app\*.ts
```

如果通过 `HTTP_INTERCEPTORS` 注册，保持不变（已在 Task 1 中通过 `withInterceptorsFromDi()` 兼容）。

### Step 2.6 — 检查 checkAuth() 调用

确认 `app.component.ts` 中仍有 `checkAuth()` 调用：

```typescript
// app.component.ts — 确认存在
export class AppComponent implements OnInit {
  constructor(private oidcSecurityService: OidcSecurityService) {}

  ngOnInit(): void {
    this.oidcSecurityService.checkAuth().subscribe(({ isAuthenticated }) => {
      console.log('Auth status:', isAuthenticated);
    });
  }
}
```

### Step 2.7 — 验证并提交

```powershell
npm run build
npm start
```

测试完整登录流程：登录 → 获取 token → 访问受保护页面 → 登出。

```powershell
git add .
git commit -m "refactor: migrate AuthModule.forRoot() to provideAuth()"
```

---

## Task 3 — 控制流语法迁移

**优先级：中　|　风险：低　|　影响范围：所有模板文件**

将 `*ngIf` / `*ngFor` / `*ngSwitch` 迁移为 `@if` / `@for` / `@switch` 新语法。

### Step 3.1 — 运行自动迁移工具

```powershell
ng generate @angular/core:control-flow
```

工具会扫描所有模板文件并自动替换。

### Step 3.2 — 人工检查 `@for` 的 track 表达式

自动迁移时，`trackBy` 函数会被转换为 `track` 表达式，**这是最容易出错的地方**。

**迁移前：**

```html
<li *ngFor="let item of items; trackBy: trackById">{{ item.name }}</li>
```

```typescript
// component.ts
trackById(index: number, item: any): number {
  return item.id;
}
```

**自动迁移后（需检查）：**

```html
@for (item of items; track item.id) {
  <li>{{ item.name }}</li>
}
```

**检查要点：**

1. `track` 后面的表达式是否正确（应该是 `item.id`，不是 `trackById`）
2. 如果原来的 `trackBy` 函数逻辑复杂（如多字段组合），需要手动调整 `track` 表达式
3. `@for` 必须有 `track`，这是必填项

### Step 3.3 — 人工检查 `@if` / `@else` 嵌套

**迁移前：**

```html
<div *ngIf="isLoaded; else loading">
  内容
</div>
<ng-template #loading>
  加载中...
</ng-template>
```

**迁移后（需检查）：**

```html
@if (isLoaded) {
  <div>内容</div>
} @else {
  加载中...
}
```

确认 `@else` 块的内容完整，没有遗漏。

### Step 3.4 — 搜索遗漏的旧语法

```powershell
findstr /s /i "*ngIf" src\app\*.html
findstr /s /i "*ngFor" src\app\*.html
findstr /s /i "*ngSwitch" src\app\*.html
```

如有遗漏，手动迁移。

### Step 3.5 — 语法对照速查

| 旧语法 | 新语法 |
|--------|--------|
| `*ngIf="condition"` | `@if (condition) { ... }` |
| `*ngIf="condition; else tpl"` | `@if (condition) { ... } @else { ... }` |
| `*ngFor="let item of items; trackBy: fn"` | `@for (item of items; track item.id) { ... }` |
| `[ngSwitch]="value"` + `*ngSwitchCase` | `@switch (value) { @case (val) { ... } }` |
| `*ngSwitchDefault` | `@default { ... }` |

### Step 3.6 — 验证并提交

```powershell
npm run build
npm start
```

逐页检查，确认页面渲染正常。

```powershell
git add .
git commit -m "refactor: migrate to new control flow syntax (@if, @for, @switch)"
```

---

## Task 4 — ComponentFactoryResolver 移除

**优先级：中　|　风险：中　|　影响范围：动态组件创建**

`ComponentFactoryResolver` 在 Angular 13 起已废弃，Angular 19 中仍可用但应迁移。

### Step 4.1 — 搜索项目中的用法

```powershell
findstr /s /i "ComponentFactoryResolver" src\app\*.ts
```

如果返回零结果，**跳过此 Task**。

### Step 4.2 — 迁移到 ViewContainerRef.createComponent()

**修改前：**

```typescript
import { ComponentFactoryResolver, ViewContainerRef } from '@angular/core';

@Component({ ... })
export class DynamicHostComponent {
  constructor(
    private viewContainerRef: ViewContainerRef,
    private componentFactoryResolver: ComponentFactoryResolver
  ) {}

  loadComponent(component: Type<any>): void {
    const factory = this.componentFactoryResolver.resolveComponentFactory(component);
    this.viewContainerRef.clear();
    this.viewContainerRef.createComponent(factory);
  }
}
```

**修改后：**

```typescript
import { ViewContainerRef, Type } from '@angular/core';

@Component({ ... })
export class DynamicHostComponent {
  constructor(
    private viewContainerRef: ViewContainerRef
    // ComponentFactoryResolver 已移除
  ) {}

  loadComponent(component: Type<any>): void {
    this.viewContainerRef.clear();
    this.viewContainerRef.createComponent(component);  // 直接传入组件类
  }
}
```

**关键变更：**

1. 移除 `ComponentFactoryResolver` 的 import 和注入
2. 直接将组件类传给 `createComponent()`，不再需要先创建 factory

### Step 4.3 — 验证并提交

```powershell
findstr /s /i "ComponentFactoryResolver" src\app\*.ts
```

确认零结果。

```powershell
npm run build
npm start
git add .
git commit -m "refactor: remove deprecated ComponentFactoryResolver"
```

---

## Task 5 — RouterModule.forRoot() → provideRouter()

**优先级：低　|　风险：低　|　影响范围：路由配置**

此迁移为可选，`RouterModule.forRoot()` 在 Angular 19 中仍然完全支持。

### Step 5.1 — 查看当前路由配置

```powershell
findstr /s /i "RouterModule.forRoot" src\app\*.ts src\app\*.module.ts
```

### Step 5.2 — 迁移（如需要）

**修改前：**

```typescript
import { RouterModule, Routes } from '@angular/router';

const routes: Routes = [
  { path: '', component: HomeComponent },
  { path: 'profile', component: ProfileComponent },
  // ...
];

@NgModule({
  imports: [
    RouterModule.forRoot(routes),
  ],
})
```

**修改后：**

```typescript
import { provideRouter } from '@angular/router';
import { Routes } from '@angular/router';

const routes: Routes = [
  { path: '', component: HomeComponent },
  { path: 'profile', component: ProfileComponent },
  // ...
];

@NgModule({
  providers: [
    provideRouter(routes),
  ],
})
```

> 💡 注意：如果路由配置中使用了 `RouterModule.forChild()`（子模块路由），这些**不需要修改**。只需要迁移根路由的 `forRoot()`。

### Step 5.3 — 验证并提交

```powershell
npm run build
npm start
```

测试所有路由跳转正常。

```powershell
git add .
git commit -m "refactor: migrate RouterModule.forRoot() to provideRouter()"
```

---

## Task 6 — APP_INITIALIZER → provideAppInitializer()

**优先级：低　|　风险：低　|　影响范围：应用初始化逻辑**

此迁移为可选，`APP_INITIALIZER` 在 Angular 19 中仍然完全支持。

### Step 6.1 — 搜索用法

```powershell
findstr /s /i "APP_INITIALIZER" src\app\*.ts
```

如果返回零结果，**跳过此 Task**。

### Step 6.2 — 迁移（如需要）

**修改前：**

```typescript
import { APP_INITIALIZER } from '@angular/core';

function initializeApp(configService: ConfigService) {
  return () => configService.loadConfig();
}

@NgModule({
  providers: [
    {
      provide: APP_INITIALIZER,
      useFactory: initializeApp,
      deps: [ConfigService],
      multi: true,
    },
  ],
})
```

**修改后：**

```typescript
import { provideAppInitializer, inject } from '@angular/core';

@NgModule({
  providers: [
    provideAppInitializer(() => {
      const configService = inject(ConfigService);
      return configService.loadConfig();
    }),
  ],
})
```

### Step 6.3 — 验证并提交

```powershell
npm run build
npm start
git add .
git commit -m "refactor: migrate APP_INITIALIZER to provideAppInitializer()"
```

---

## Task 7 — UI 回归测试

**优先级：必须　|　建议在所有代码迁移完成后进行**

### Step 7.1 — ngx-bootstrap 样式检查

确认 `app.component.ts` 中 `setTheme('bs5')` 调用仍存在：

```powershell
findstr /s /i "setTheme" src\app\*.ts
```

应该找到类似：

```typescript
import { setTheme } from 'ngx-bootstrap/utils';

export class AppComponent {
  constructor() {
    setTheme('bs5');
  }
}
```

如果缺失，**必须补回**，否则所有 ngx-bootstrap 组件的样式会异常。

### Step 7.2 — 重点检查页面清单

以下组件在升级后最容易出现样式或行为问题：

| 组件 | 检查内容 | 来源库 |
|------|---------|--------|
| Modal 弹窗 | 打开/关闭/遮罩层是否正常 | ngx-bootstrap / ng-bootstrap |
| Dropdown 下拉菜单 | 展开/收起/选中是否正常 | ngx-bootstrap / ng-bootstrap |
| Tooltip 提示 | 悬停/定位是否正常 | ngx-bootstrap / ng-bootstrap |
| Datepicker 日期选择器 | 打开/选择/格式化是否正常 | ngx-bootstrap |
| Table 分页/排序 | 翻页/排序/筛选是否正常 | Angular Material |
| Form 表单 | 验证/提交/错误提示是否正常 | Angular Forms |
| Navigation 导航 | 路由跳转/菜单高亮是否正常 | Angular Router |

### Step 7.3 — 运行自动测试

```powershell
npm test
```

对比升级前后的测试通过率。

### Step 7.4 — Production 构建测试

```powershell
npm run deploy
```

确认 prod 模式构建无 error。

### Step 7.5 — 提交测试结果

```powershell
git add .
git commit -m "test: post-upgrade regression testing complete"
```

---

## Task 8 — npm 漏洞处理

**优先级：收尾　|　在所有功能迁移和测试完成后进行**

### Step 8.1 — 查看当前漏洞

```powershell
npm audit
```

### Step 8.2 — 安全修复（不影响大版本）

```powershell
npm audit fix
```

> ⚠️ **不要使用 `npm audit fix --force`**，这可能会降级 Angular 或其他关键包。

### Step 8.3 — 如果 audit fix 无法修复所有漏洞

手动查看具体漏洞包，评估是否：

1. 漏洞仅影响开发环境（devDependencies）→ 风险较低，可记录后暂缓处理
2. 漏洞影响生产环境 → 需要单独升级该包或寻找替代

### Step 8.4 — 验证并提交

```powershell
npm run build
npm test
git add .
git commit -m "chore: fix npm audit vulnerabilities"
```

---

## 附录 A — 每次迁移的标准验证流程

每个 Task 完成后，按以下顺序验证：

```powershell
# 1. 编译检查
npm run build

# 2. 本地运行
npm start
# → 手动测试相关功能

# 3. Production 构建（关键 Task 后执行）
npm run deploy

# 4. 自动测试
npm test

# 5. 提交
git add .
git commit -m "<commit message>"
```

如果任何步骤失败：

1. 检查终端输出的 error 信息
2. 对比修改前后的代码 `git diff`
3. 如无法修复，回退到上一次提交：`git checkout -- .`

---

## 最终提交与合并

所有 Task 完成后：

```powershell
# 推送到远端
git push origin upgrade/angular-19

# 创建 PR，合并到主分支
# PR 标题示例：chore: Angular v17 → v19 upgrade with API migrations
# PR 描述中列出所有变更摘要
```

---

*如遇到本文档未覆盖的问题，请参考 [angular.dev/update-guide](https://angular.dev/update-guide) 或联系架构组。*