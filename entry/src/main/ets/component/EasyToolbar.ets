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
      Row() {
        Text(this.title)
          .fontColor(Color.Black)
          .fontSize(19)
          .fontWeight(500)
          .margin({ left: 20 })

        Text() {
          SymbolSpan(this.pictureIconSrc)
            .width(22)
            .height(22)
            .fontWeight(FontWeight.Normal)
            .fontSize(96)
        }.onClick(() => {
          this.clickPicture
        })

        Text() {
          SymbolSpan(this.historyIconSrc)
            .width(22)
            .height(22)
            .fontWeight(FontWeight.Normal)
            .fontSize(96)
        }.onClick(() => {
          this.clickHistory
        })

        Text() {
          SymbolSpan(this.moreIconSrc)
            .width(22)
            .height(22)
            .fontWeight(FontWeight.Normal)
            .fontSize(96)
        }.onClick(() => {
          this.clickMore
        })
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