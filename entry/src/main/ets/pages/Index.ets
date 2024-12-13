import EasyToolbar from '../component/EasyToolbar';
import WindowManager from '../utils/WindowManager';
// 导入图片识码需要的日志和picker模块

@Entry
@Component
struct Index {

  private clickPicture() {
  }

  private clickHistory() {

  }

  private clickMore() {

  }
  build() {
    Column() {
      EasyToolbar({
        clickPicture: (): void => {
          this.clickPicture()
        },
        clickHistory: (): void => {
          this.clickHistory()
        },
        clickMore: (): void => {
          this.clickMore()
        }
      })
    }
    .width("100%")
    .height("100%")
    .backgroundColor("#f4f4f4")
    .layoutWeight(1)
    .padding({ bottom: WindowManager.navBarHeight })
  }
}