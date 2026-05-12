:host ::ng-deep .no-texting-popover {
  // 覆盖 ng-bootstrap 默认 popover 容器样式
  max-width: 520px;          // 图1的卡片是比较宽的
  border: none;
  border-radius: 6px;
  box-shadow: 0 6px 24px rgba(0, 0, 0, 0.12);
  background: #fff;

  // 隐藏 popover 默认的小箭头（图1是纯卡片，没有指向箭头）
  .popover-arrow,
  &::before,
  &::after {
    display: none !important;
  }

  // ng-bootstrap 内部容器
  .popover-body {
    padding: 0;              // 我们自己控制内边距
    color: inherit;
  }
}

.no-texting-link {
  color: #0070c0;
  cursor: pointer;

  &:hover { text-decoration: underline; }
}

// 卡片内容布局
.no-texting-alert {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  padding: 20px 24px;
}

.no-texting-alert-icon {
  color: #0070c0;            // 蓝色三角，匹配图1
  font-size: 32px;
  flex-shrink: 0;
  margin-top: 2px;
}

.no-texting-alert-content {
  flex: 1;
}

.no-texting-alert-title {
  color: #0070c0;
  font-size: 16px;
  font-weight: 600;
  letter-spacing: 0.5px;
  margin-bottom: 8px;
}

.no-texting-alert-list {
  margin: 0 0 16px 0;
  padding-left: 20px;
  color: #333;
  font-size: 13px;
  line-height: 1.6;

  li { margin-bottom: 4px; }

  a {
    color: #0070c0;
    text-decoration: none;
    &:hover { text-decoration: underline; }
  }
}

.no-texting-alert-footer {
  display: flex;
  justify-content: center;
}

.no-texting-ok-btn {
  min-width: 80px;
  padding: 6px 28px;
  border-radius: 24px;       // 胶囊形，匹配图1
  background-color: #0070c0;
  border: none;
  color: #fff;
  font-weight: 500;

  &:hover {
    background-color: #005a9e;
    color: #fff;
  }
}
