//定义标题栏左侧的页签项目类
export class tabItem {
  title: ResourceStr;
  icon?: ResourceStr;
  constructor(title: ResourceStr,icon?: ResourceStr) {
    this.title = title
    this.icon = icon
  }
}