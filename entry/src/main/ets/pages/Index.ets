import EasyToolbar from '../component/EasyToolbar';
import WindowManager from '../utils/WindowManager';
import { image } from '@kit.ImageKit';
import { FileUtil, ScanUtil, ToastUtil } from '@pura/harmony-utils';

@Entry
@Component
struct Index {
  private readonly fileName: string = "qr_code.png";
  @State filePath: string = '';
  @State pixelMap?: image.PixelMap = undefined;
  @State scanStr1: string = '';
  @State scanStr2: string = '';
  @State scanStr3: string = '';

  aboutToAppear(): void {
    this.filePath = FileUtil.getFilesDirPath("",this.fileName)
    if (!ScanUtil.canIUseScan()) {
      ToastUtil.showToast("当前设备不支持码能力！")
    }
  }





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