:host ::ng-deep .no-texting-popover {
  max-width: 580px;
  border: none;
  border-radius: 6px;
  box-shadow: 0 6px 24px rgba(0, 0, 0, 0.15);
  background: #fff;

  .popover-arrow,
  &::before,
  &::after {
    display: none !important;
  }

  .popover-body {
    padding: 0;
    color: inherit;
  }
}

.no-texting-link {
  color: #0070c0;
  cursor: pointer;
  &:hover { text-decoration: underline; }
}

.no-texting-alert {
  display: flex;
  align-items: flex-start;
  gap: 20px;
  padding: 22px 28px;
}

.no-texting-alert-icon {
  color: #0070c0;
  font-size: 38px;
  flex-shrink: 0;
  line-height: 1;
  margin-top: 2px;
}

.no-texting-alert-content { flex: 1; }

.no-texting-alert-title {
  color: #0070c0;
  font-size: 18px;
  font-weight: 600;
  letter-spacing: 0.5px;
  margin-bottom: 10px;
}

.no-texting-alert-list {
  margin: 0;                  // 去掉了底部 margin（之前留给 footer 的）
  padding-left: 22px;
  color: #333;
  font-size: 15px;
  line-height: 1.65;

  li { margin-bottom: 6px; }
  li:last-child { margin-bottom: 0; }

  a {
    color: #0070c0;
    text-decoration: none;
    &:hover { text-decoration: underline; }
  }
}
