import router from '@ohos.router'
import prompt from '@ohos.promptAction'
import WindowManager from '../utils/WindowManager'

@Preview
@Component
export default struct WechatToolbar {
  private title: string = "发现"

  build() {
    Column() {
      Stack() {
      }
      .width("100%")
      .height(53)
    }.backgroundColor("#f0f0f0")
    .padding({ top: WindowManager.statusBarHeight })
  }
}