import { scanCore, scanBarcode, customScan } from '@kit.ScanKit';
// 导入功能涉及的权限申请、回调接口
import { router, promptAction, display } from '@kit.ArkUI';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common, abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { PermissionUtils } from '../utils/PermissionUtils';

const TAG = '[YUV CPSample]';
let context = getContext(this) as common.UIAbilityContext;


@Extend(Column)
function mainStyle() {
  .width('100%')
  .height('100%')
  .padding({
    top: 40
  })
  .justifyContent(FlexAlign.Center)
}

@Entry
@Component
struct YUVScan {
  @State userGrant: boolean = false // 是否已申请相机权限
  @State surfaceId: string = '' // xComponent组件生成id
  @State cameraHeight: number = 640 // 设置预览流高度，默认单位：vp
  @State cameraWidth: number = 360 // 设置预览流宽度，默认单位：vp
  @State zoomValue: number = 1 // 预览流缩放比例
  @State setZoomValue: number = 1 // 已设置的预览流缩放比例
  @State isReleaseCamera: boolean = false // 是否已释放相机流
  @State scanWidth: number = 384 // xComponent宽度，默认设置384，单位vp
  @State scanHeight: number = 682 // xComponent高度，默认设置682，单位vp
  @State scanBottom: number = 220
  @State offsetX: number = 0 // xComponent位置x轴偏移量，单位vp
  @State offsetY: number = 0 // xComponent位置y轴偏移量，单位vp
  @State scanCodeRect: Array<scanBarcode.ScanCodeRect> = [] // 扫码结果码图位置
  @State scanFlag: boolean = false // 是否已经扫码到结果
  @State scanFrameResult: string = ''
  @State scaleValue: number = 1 // 屏幕缩放比
  @State pinchValue: number = 1 // 双指缩放比例
  @State displayHeight: number = 0 // 屏幕高度，单位vp
  @State displayWidth: number = 0 // 屏幕宽度，单位vp
  private mXComponentController: XComponentController = new XComponentController()
  private viewControl: customScan.ViewControl = { width: 1920, height: 1080, surfaceId: this.surfaceId }
  options: scanBarcode.ScanOptions = {
    // 扫码类型，可选参数
    scanTypes: [scanCore.ScanType.ALL],
    // 是否开启多码识别，可选参数
    enableMultiMode: true,
    // 是否开启相册扫码，可选参数
    enableAlbum: true,
  }
  // 返回自定义扫描结果的回调
  private callback: AsyncCallback<scanBarcode.ScanResult[]> =
    async (error: BusinessError, result: scanBarcode.ScanResult[]) => {
      if (error && error.code) {
        hilog.error(0x0001, TAG,
          `Failed to get ScanResult by callback. Code: ${error.code}, message: ${error.message}`);
        return;
      }
      // 解析码值结果跳转应用服务页
      hilog.info(0x0001, TAG, `Succeeded in getting ScanResult by callback, result: ${JSON.stringify(result)}`);
    }
  // 返回相机帧的回调
  private frameCallback: AsyncCallback<customScan.ScanFrame> =
    async (error: BusinessError, frameResult: customScan.ScanFrame) => {
      if (error) {
        hilog.error(0x0001, TAG, `Failed to get ScanFrame by callback. Code: ${error.code}, message: ${error.message}`);
        return;
      }
      // byteBuffer相机YUV图像数组
      hilog.info(0x0001, TAG,
        `Succeeded in getting ScanFrame.byteBuffer.byteLength: ${frameResult.byteBuffer.byteLength}`)
      hilog.info(0x0001, TAG, `Succeeded in getting ScanFrame.width: ${frameResult.width}`)
      hilog.info(0x0001, TAG, `Succeeded in getting ScanFrame.height: ${frameResult.height}`)
      this.scanFrameResult = JSON.stringify(frameResult.scanCodeRects);
      if (frameResult && frameResult.scanCodeRects && frameResult.scanCodeRects.length > 0 && !this.scanFlag) {
        if (frameResult.scanCodeRects[0]) {
          this.stopCamera();
          this.scanCodeRect = [];
          this.scanFlag = true;
          // 码图位置信息转换
          this.changeToXComponent(frameResult);
        } else {
          this.scanFlag = false;
        }
      }
    }

  // frameCallback横向码图位置信息转换为预览流xComponent对应码图位置信息
  changeToXComponent(frameResult: customScan.ScanFrame) {
    if (frameResult && frameResult.scanCodeRects) {
      let frameHeight = frameResult.height;
      let ratio = this.scanWidth / frameHeight;
      frameResult.scanCodeRects.forEach((item) => {
        this.scanCodeRect.push({
          left: this.toFixedNumber((frameHeight - item.bottom) * ratio),
          top: this.toFixedNumber(item.left * ratio),
          right: this.toFixedNumber((frameHeight - item.top) * ratio),
          bottom: this.toFixedNumber(item.right * ratio)
        });
      });
      this.scanFrameResult = JSON.stringify(this.scanCodeRect);
    }
  }

  toFixedNumber(no: number): number {
    return Number((no).toFixed(1));
  }

  async onPageShow() {
    // 自定义启动第一步，用户申请权限
    const permissions: Array<Permissions> = ['ohos.permission.CAMERA'];
    // 自定义启动第二步：设置预览流布局尺寸
    this.setDisplay();
    let grantStatus = await PermissionUtils.checkAccessToken(permissions[0]);
    if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      // 已经授权，可以继续访问目标操作
      this.userGrant = true;
      if (this.surfaceId) {
        // 自定义启动第三步，初始化接口
        this.initCamera();
      }
    } else {
      // 申请相机权限
      this.requestCameraPermission();
    }
  }

  async onPageHide() {
    this.releaseCamera();
  }

  // 用户申请权限
  async requestCameraPermission() {
    let grantStatus = await PermissionUtils.reqPermissionsFromUser()
    let length: number = grantStatus.length;
    for (let i = 0; i < length; i++) {
      if (grantStatus[i] === 0) {
        // 用户授权，可以继续访问目标操作
        this.userGrant = true;
      } else {
        // 用户拒绝授权，提示用户必须授权才能访问当前页面的功能，并引导用户到系统设置中打开相应的权限
        this.userGrant = false;
      }
    }
  }

  // 竖屏时获取屏幕尺寸，设置预览流全屏示例
  setDisplay() {
    try {
      // 以手机为例计算宽高
      let displayClass = display.getDefaultDisplaySync();
      this.displayHeight = px2vp(displayClass.height);
      this.displayWidth = px2vp(displayClass.width);
      if (displayClass !== null) {
        this.scanWidth = px2vp(displayClass.width);
        this.scanHeight = Math.round(this.scanWidth * this.viewControl.width / this.viewControl.height);
        this.scanBottom = Math.max(220, px2vp(displayClass.height) - this.scanHeight);
        this.offsetX = 0;
        this.offsetY = 0;
      }
    } catch (error) {
      hilog.error(0x0001, TAG, `Failed to getDefaultDisplaySync. Code: ${error.code}, message: ${error.message}`);
    }
  }

  // 初始化相机流
  async initCamera() {
    this.isReleaseCamera = false;
    try {
      // 自定义启动第三步，初始化接口
      customScan.init(this.options);
      hilog.info(0x0001, TAG, 'Succeeded in initting customScan with options.');
    } catch (error) {
      hilog.error(0x0001, TAG, `Failed to init customScan. Code: ${error.code}, message: ${error.message}`);
    }
    this.scanCodeRect = [];
    this.scanFlag = false;
    try {
      // 自定义启动第四步，请求扫码接口
      customScan.start(this.viewControl, this.callback, this.frameCallback);
    } catch (error) {
      hilog.error(0x0001, TAG, `Failed to start customScan. Code: ${error.code}, message: ${error.message}`);
    }
  }

  // 暂停相机流
  async stopCamera() {
    if (!this.isReleaseCamera) {
      try {
        customScan.stop();
      } catch (error) {
        hilog.error(0x0001, TAG, `Failed to stop customScan. Code: ${error.code}, message: ${error.message}`);
      }
    }
  }

  // 释放相机流
  async releaseCamera() {
    if (!this.isReleaseCamera) {
      await this.stopCamera();
      try {
        await customScan.release();
      } catch (error) {
        hilog.error(0x0001, TAG, `Failed to release customScan. Code: ${error.code}, message: ${error.message}`);
      }
      this.isReleaseCamera = true;
    }
  }

  build() {
    Stack() {
      // 相机预览流XComponent
      if (this.userGrant) {
        Column() {
          XComponent({
            id: 'componentId',
            type: XComponentType.SURFACE,
            controller: this.mXComponentController
          })
            .onLoad(() => {
              hilog.info(0x0001, TAG, 'Succeeded in loading, onLoad is called.');
              this.surfaceId = this.mXComponentController.getXComponentSurfaceId();
              hilog.info(0x0001, TAG, `Succeeded in getting surfaceId is ${this.surfaceId}`);
              this.viewControl = { width: this.scanWidth, height: this.scanHeight, surfaceId: this.surfaceId };
              // 启动相机进行扫码
              this.initCamera();
            })
            .height(this.scanHeight)
            .width(this.scanWidth)
            .position({ x: 0, y: 0 })
        }
        .height('100%')
        .width('100%')
        .position({ x: this.offsetX, y: this.offsetY })
      }

      Column() {
        this.TopTool()
        Column() {
        }
        .layoutWeight(1)
        .width('100%')

        Column() {

          Row() {
            // 闪光灯按钮，启动相机流后才能使用
            Text('轻触照亮') {
              SymbolSpan( $r('sys.symbol.flashlight_on_fill'))
                .width(22)
                .height(22)
                .fontWeight(FontWeight.Normal)
                .fontSize(96)
            }.onClick(() => {
                let lightStatus: boolean = false;
                try {
                  lightStatus = customScan.getFlashLightStatus();
                } catch (error) {
                  hilog.error(0x0001, TAG,
                    `Failed to get flashLightStatus. Code: ${error.code}, message: ${error.message}`);
                }
                // 根据当前闪光灯状态，选择打开或关闭闪关灯
                if (lightStatus) {
                  try {
                    customScan.closeFlashLight();
                  } catch (error) {
                    hilog.error(0x0001, TAG,
                      `Failed to close flashLight. Code: ${error.code}, message: ${error.message}`);
                  }
                } else {
                  try {
                    customScan.openFlashLight();
                  } catch (error) {
                    hilog.error(0x0001, TAG,
                      `Failed to open flashLight. Code: ${error.code}, message: ${error.message}`);
                  }
                }
              })
              .visibility(this.scanFlag ? Visibility.None : Visibility.Visible)
          }

          Row() {
            // 预览流设置缩放比例
            Button('缩放比例还原' )
              .width(100)
              .alignSelf(ItemAlign.Center)
              .onClick(() => {
                // 设置相机缩放比例
                if (!this.scanFlag) {
                  if (!this.zoomValue || this.zoomValue === this.setZoomValue) {
                    this.setZoomValue = this.customGetZoom();
                  } else {
                    this.zoomValue = this.zoomValue;
                    this.customSetZoom(this.zoomValue);
                    setTimeout(() => {
                      if (!this.scanFlag) {
                        this.setZoomValue = this.customGetZoom();
                      }
                    }, 1000);
                  }
                }
              })
          }
          .margin({ top: 10, bottom: 10 })
          .visibility(this.scanFlag ? Visibility.None : Visibility.Visible)

          // Row() {
          //   // 输入要设置的预览流缩放比例
          //   TextInput({ placeholder: '输入缩放倍数' })
          //     .width(200)
          //     .type(InputType.Number)
          //     .borderWidth(1)
          //     .backgroundColor(Color.White)
          //     .onChange(value => {
          //       this.zoomValue = Number(value);
          //     })
          // }
          // .visibility(this.scanFlag ? Visibility.None : Visibility.Visible)

          Text(this.scanFlag ? '继续扫码' : '扫码中')
            .height(30)
            .fontSize(16)
            .fontColor(Color.White)
            .onClick(() => {
              if (this.scanFlag) {
                this.scanFrameResult = '';
                this.initCamera();
              }
            })
          Text('扫码结果：' + this.scanFrameResult).fontColor(Color.White).fontSize(12)
        }
        .width('100%')
        .height(this.scanBottom)
        .backgroundColor(Color.Black)
      }
      .mainStyle()


      // 实时扫码码图中心点位置
      if (this.scanFlag && this.scanCodeRect.length > 0) {
        ForEach(this.scanCodeRect, (item: scanBarcode.ScanCodeRect, index: number) => {
          Image($rawfile('scan_selected2.svg'))
            .width(40)
            .height(40)
            .markAnchor({ x: 20, y: 20 })
            .position({
              x: (item.left + item.right) / 2 + this.offsetX,
              y: (item.top + item.bottom) / 2 + this.offsetY
            })
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.userGrant ? Color.Transparent : Color.Black)
    .onClick((event: ClickEvent) => {
      // 是否已扫描到结果
      if (this.scanFlag) {
        return;
      }
      // 点击屏幕位置，获取点击位置(x,y)，设置相机焦点
      let x1 = vp2px(event.displayY) / (this.displayHeight + 0.0);
      let y1 = 1.0 - (vp2px(event.displayX) / (this.displayWidth + 0.0));
      try {
        customScan.setFocusPoint({ x: x1, y: y1 });
        hilog.info(0x0001, TAG, `Succeeded in setting focusPoint x1: ${x1}, y1: ${y1}`);
      } catch (error) {
        hilog.error(0x0001, TAG, `Failed to set focusPoint. Code: ${error.code}, message: ${error.message}`);
      }
      setTimeout(() => {
        try {
          customScan.resetFocus();
        } catch (error) {
          hilog.error(0x0001, TAG, `Failed to reset Focus. Code: ${error.code}, message: ${error.message}`);
        }
      }, 200);
    })
    .gesture(PinchGesture({ fingers: 2 })
      .onActionStart((event: GestureEvent) => {
        hilog.info(0x0001, TAG, 'Pinch start');
      })
      .onActionUpdate((event: GestureEvent) => {
        if (event) {
          this.scaleValue = event.scale;
        }
      })
      .onActionEnd((event: GestureEvent) => {
        // 是否已扫描到结果
        if (this.scanFlag) {
          return;
        }
        // 获取双指缩放比例，设置变焦比
        try {
          let zoom = this.customGetZoom();
          this.pinchValue = this.scaleValue * zoom;
          this.customSetZoom(this.pinchValue);
          hilog.info(0x0001, TAG, 'Pinch end');
        } catch (error) {
          hilog.error(0x0001, TAG, `Failed to setZoom. Code: ${error.code}, message: ${error.message}`);
        }
      }))
  }

  // 自定义扫码界面的顶部返回按钮和扫码提示
  @Builder
  TopTool() {
    Column() {
      Column() {
        Text('对准二维码/条形码，即可自动扫描')
      }.margin({ left: 24, right: 24, top: 24 })
    }
    .height(146)
    .width('100%')
  }

  public customGetZoom(): number {
    let zoom = 1;
    try {
      zoom = customScan.getZoom();
      hilog.info(0x0001, TAG, `Succeeded in getting Zoom, zoom: ${zoom}`);
    } catch (error) {
      hilog.error(0x0001, TAG, `Failed to getZoom. Code: ${error.code}, message: ${error?.message}`);
    }
    return zoom;
  }

  public customSetZoom(pinchValue: number): void {
    try {
      customScan.setZoom(pinchValue);
      hilog.info(0x0001, TAG, `Succeeded in setting Zoom.`);
    } catch (error) {
      hilog.error(0x0001, TAG, `Failed to setZoom. Code: ${error.code}, message: ${error?.message}`);
    }
  }
}