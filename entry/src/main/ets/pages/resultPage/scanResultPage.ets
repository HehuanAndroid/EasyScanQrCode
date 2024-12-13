import { DividerTmp } from '../../entity/DividerTmp';
import { ScanResults } from '../../model/ScanService';
import { ScanResultsUtils } from '../../utils/ScanResultsUtils';

@Entry
@Component
struct ScanResultPage {
  @State scanResultList: ScanResults[] =[];
  @State egDivider: DividerTmp = new DividerTmp(1, 60, 10, '#ffe9f0f0')

  // aboutToAppear(): void {
  //   this.scanResultList=await ScanResultsUtils.retrieveAndSortScanResults()
  // }
  // 生命周期方法，在组件即将出现时调用
  async aboutToAppear(): Promise<void> {
    try {
      // 等待 Promise 解析，并将结果赋值给 scanResultList
      this.scanResultList = await ScanResultsUtils.retrieveAndSortScanResults();
    } catch (error) {
      // 处理错误，例如打印到控制台或设置错误状态
      console.error('Failed to retrieve and sort scan results:', error);
      // 如果需要，您可以在这里设置错误状态或执行其他错误处理逻辑
    }
  }
  build() {
    List() {
      ForEach(this.scanResultList, (item: ScanResults) => {
        ListItem(){
          Row() {
            Text(item.uri)
              .width(40)
              .height(40)
              .margin(10)
            Text(`${item.code}`).fontSize(20)
            Text(`${item.data}`).fontSize(20)
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
        }
      }, (item: ScanResults) => JSON.stringify(item))
    }
    .height('100%')
    .width('100%')
    .listDirection(Axis.Vertical)
    .divider(this.egDivider)
  }
}