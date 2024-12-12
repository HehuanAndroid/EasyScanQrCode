//定义标题栏右侧菜单项目接口
export interface menuItem {
  value: ResourceStr;
  isEnabled?: boolean;
  action?: () => void
}