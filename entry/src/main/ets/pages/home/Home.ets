import router from '@ohos.router'
import WechatToolbar from '../../component/WechatToolbar'

@Preview
@Component
export default struct Home {

  build() {
    Column() {
      WechatToolbar()
    }
    .width("100%")
    .height("100%")
    .backgroundColor("#f0f0f0")
  }
}
