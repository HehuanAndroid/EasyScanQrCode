import router from '@ohos.router'
import prompt from '@ohos.promptAction'
import WindowManager from '../utils/WindowManager'
import { tabItem } from '../entity/tabItem'
import { menuItem } from '../entity/menuItem'
import { TabTitleBar } from '@kit.ArkUI'

@Preview
@Component
export default struct EasyToolbar {
  clickPicture = (): void => {

  }
  clickHistory = (): void => {

  }
  clickMore = (): void => {

  }
  private title: string = "二维码工具"
  private historyIconSrc: Resource = $r("sys.symbol.arrow_counterclockwise_clock")
  private pictureIconSrc: Resource = $r("sys.symbol.picture_fill")
  private moreIconSrc: Resource = $r("sys.symbol.more")

  build() {
    Column() {
      Row({space:20}) {
        Text(this.title)
          .fontColor(Color.Black)
          .fontSize(19)
          .fontWeight(500)
          .margin({ left: 20 })

        Row({space:10}){
          Text() {
            SymbolSpan(this.pictureIconSrc)
              .fontSize(30)
              .fontWeight(FontWeight.Normal)
          }.onClick(() => {
            this.clickPicture
          })

          Text() {
            SymbolSpan(this.historyIconSrc)
              .fontSize(30)
              .fontWeight(FontWeight.Normal)
          }.onClick(() => {
            this.clickHistory
          })

          Text() {
            SymbolSpan(this.moreIconSrc)
              .fontSize(30)
              .fontWeight(FontWeight.Normal)
          }.onClick(() => {
            this.clickMore
          })
        }
        .margin({right:20})
      }
      .height(53)
      .width("100%")
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .expandSafeArea([SafeAreaType.KEYBOARD])
    .backgroundColor("#f1f1f1")
    .zIndex(999)
    .padding({ top: WindowManager.statusBarHeight })
  }
}