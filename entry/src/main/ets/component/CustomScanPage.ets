import { scanCore, scanBarcode, customScan } from '@kit.ScanKit';
// 导入功能涉及的权限申请、回调接口
import { router, promptAction, display } from '@kit.ArkUI';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common, abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { CommonTipsDialog } from '../common/CommonTipsDialog';
import { PermissionUtils } from '../utils/PermissionUtils';
import Logger from '../common/Logger';


const TAG: string = '[customScanPage]';

@Entry
@Component
struct CustomScanPage {
  @State userGrant: boolean = false // 是否已申请相机权限
  @State surfaceId: string = '' // xComponent组件生成id
  @State isShowBack: boolean = false // 是否已经返回扫码结果
  @State isFlashLightEnable: boolean = false // 是否开启了闪光灯
  @State isSensorLight: boolean = false // 记录当前环境亮暗状态
  @State cameraHeight: number = 640 // 设置预览流高度，默认单位：vp
  @State cameraWidth: number = 360 // 设置预览流宽度，默认单位：vp
  @State offsetX: number = 0 // 设置预览流x轴方向偏移量，默认单位：vp
  @State offsetY: number = 0 // 设置预览流y轴方向偏移量，默认单位：vp
  @State zoomValue: number = 1 // 预览流缩放比例
  @State setZoomValue: number = 1 // 已设置的预览流缩放比例
  @State scaleValue: number = 1 // 屏幕缩放比
  @State pinchValue: number = 1 // 双指缩放比例
  @State displayHeight: number = 0 // 屏幕高度，单位vp
  @State displayWidth: number = 0 // 屏幕宽度，单位vp
  @State scanResult: Array<scanBarcode.ScanResult> = [] // 扫码结果
  private mXComponentController: XComponentController = new XComponentController()
  @State isDialogShow: boolean = false;
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CommonTipsDialog({
      isDialogShow: this.isDialogShow
    }),
    autoCancel: false,
    customStyle: false,
    alignment: DialogAlignment.Center
  });

  async onPageShow() {
    // 自定义启动第一步，用户申请权限
    await this.empowerment();
    // await this.requestCameraPermission();
    // 多码扫码识别，enableMultiMode: true 单码扫码识别enableMultiMode: false
    let options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: true,
      enableAlbum: true
    }
    // 自定义启动第二步：设置预览流布局尺寸
    this.setDisplay();
    try {
      // 自定义启动第三步，初始化接口
      customScan.init(options);
    } catch (error) {
      hilog.error(0x0001, TAG, `Failed to init customScan. Code: ${error.code}, message: ${error.message}`);
    }
  }

  async onPageHide() {
    // 页面消失或隐藏时，停止并释放相机流
    this.userGrant = false;
    this.isFlashLightEnable = false;
    this.isSensorLight = false;
    try {
      customScan.off('lightingFlash');
    } catch (error) {
      hilog.error(0x0001, TAG, `Failed to off lightingFlash. Code: ${error.code}, message: ${error.message}`);
    }
    this.customScanStop();

    try {
      // 自定义相机流释放接口
      customScan.release().then(() => {
        hilog.info(0x0001, TAG, 'Succeeded in releasing customScan by promise.');
      }).catch((error: BusinessError) => {
        hilog.error(0x0001, TAG,
          `Failed to release customScan by promise. Code: ${error.code}, message: ${error.message}`);
      })
    } catch (error) {
      hilog.error(0x0001, TAG, `Failed to release customScan. Code: ${error.code}, message: ${error.message}`);
    }
    this.dialogController.close();
  }

  async empowerment() {
    const permissions: Array<Permissions> = ['ohos.permission.CAMERA'];
    let grantStatus = await PermissionUtils.checkAccessToken(permissions[0]);
    if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      // If the user has granted the permission, the operation is allowed.
      this.userGrant = true;
    } else {
      // Apply for the camera permission.
      this.requestCameraPermission();
    }
  }


  // 用户申请权限
  async reqPermissionsFromUser(): Promise<number[]> {
    hilog.info(0x0001, TAG, 'reqPermissionsFromUser start');
    let context = getContext() as common.UIAbilityContext;
    let atManager = abilityAccessCtrl.createAtManager();
    let grantStatus = await atManager.requestPermissionsFromUser(context, ['ohos.permission.CAMERA']);
    return grantStatus.authResults;
  }

  // 用户申请相机权限
  async requestCameraPermission() {
    let grantStatus = await PermissionUtils.reqPermissionsFromUser();
    let length: number = grantStatus.length;
    for (let i = 0; i < length; i++) {
      if (grantStatus[i] === 0) {
        // The user has granted the permission.
        Logger.info(TAG, 'Succeeded in requesting permissions from user.');
        this.userGrant = true;
        if (this.isDialogShow) {
          this.isDialogShow = false;
          this.dialogController.close();
        }
      } else {
        // If the user refuses to grant the permission, display a message indicating that user authorization is required, and direct the user to set the permission in system settings.
        Logger.info(TAG, `Failed to requesting permissions from user.`);
        this.userGrant = false;
        if (!this.isDialogShow) {
          this.dialogController.open();
          this.isDialogShow = true;
        }
      }
    }
  }

  // 竖屏时获取屏幕尺寸，设置预览流全屏示例
  setDisplay() {
    try {
      // 默认竖屏
      let displayClass = display.getDefaultDisplaySync();
      this.displayHeight = px2vp(displayClass.height);
      this.displayWidth = px2vp(displayClass.width);
      let maxLen: number = Math.max(this.displayWidth, this.displayHeight);
      let minLen: number = Math.min(this.displayWidth, this.displayHeight);
      const RATIO: number = 16 / 9;
      this.cameraHeight = maxLen;
      this.cameraWidth = maxLen / RATIO;
      this.offsetX = (minLen - this.cameraWidth) / 2;
    } catch (error) {
      hilog.error(0x0001, TAG, `Failed to getDefaultDisplaySync. Code: ${error.code}, message: ${error.message}`);
    }
  }

  // toast显示扫码结果
  async showScanResult(result: scanBarcode.ScanResult) {

    // 使用toast显示出扫码结果
    promptAction.showToast({
      message: JSON.stringify(result),
      duration: 5000
    });
  }

  initCamera() {
    this.isShowBack = false;
    this.scanResult = [];
    let viewControl: customScan.ViewControl = {
      width: this.cameraWidth,
      height: this.cameraHeight,
      surfaceId: this.surfaceId
    };
    try {
      // 自定义启动第四步，请求扫码接口，通过Promise方式回调
      customScan.start(viewControl)
        .then(async (result: Array<scanBarcode.ScanResult>) => {
          hilog.info(0x0001, TAG, `result: ${JSON.stringify(result)}`);
          if (result.length) {
            // 解析码值结果跳转应用服务页
            this.scanResult = result;
            this.isShowBack = true;
            // 获取到扫描结果后暂停相机流
            this.customScanStop();
          }
        });
    } catch (error) {
      hilog.error(0x0001, TAG, `Failed to start customScan. Code: ${error.code}, message: ${error.message}`);
    }
  }

  customScanStop() {
    try {
      customScan.stop();
    } catch (error) {
      hilog.error(0x0001, TAG, `Failed to stop customScan. Code: ${error.code}, message: ${error.message}`);
    }
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

  build() {
    Stack() {
      if (this.userGrant) {
        Column() {
          XComponent({
            id: 'componentId',
            type: XComponentType.SURFACE,
            controller: this.mXComponentController
          })
            .onLoad(async () => {
              hilog.info(0x0001, TAG, 'Succeeded in loading, onLoad is called.');
              // 获取XComponent组件的surfaceId
              this.surfaceId = this.mXComponentController.getXComponentSurfaceId();
              hilog.info(0x0001, TAG, `Succeeded in getting surfaceId: ${this.surfaceId}`);
              this.initCamera();
              // 闪光灯监听接口
              customScan.on('lightingFlash', (error, isLightingFlash) => {
                if (error) {
                  hilog.error(0x0001, TAG,
                    `Failed to on lightingFlash. Code: ${error.code}, message: ${error.message}`);
                  return;
                }
                if (isLightingFlash) {
                  this.isFlashLightEnable = true;
                } else {
                  try {
                    if (!customScan.getFlashLightStatus()) {
                      this.isFlashLightEnable = false;
                    }
                  } catch (error) {
                    hilog.error(0x0001, TAG,
                      `Failed to get FlashLightStatus. Code: ${error.code}, message: ${error.message}`);
                  }
                }
                this.isSensorLight = isLightingFlash;
              });
            })
            .width(this.cameraWidth)
            .height(this.cameraHeight)
            .position({ x: this.offsetX, y: this.offsetY })
        }
        .height('100%')
        .width('100%')
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
              SymbolSpan(this.isFlashLightEnable ? $r('sys.symbol.flashlight_on_fill'):$r('sys.symbol.flashlight_off_fill'))
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
                    setTimeout(() => {
                      this.isFlashLightEnable = this.isSensorLight;
                    }, 200);
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
              .visibility((this.userGrant && this.isFlashLightEnable) ? Visibility.Visible : Visibility.None)

            // 扫码成功后，点击按钮后重新扫码
            Button('Scan')
              .onClick(() => {
                // 点击按钮重启相机流，重新扫码
                this.initCamera();
              })
              .visibility(this.isShowBack ? Visibility.Visible : Visibility.None)
          }

          // Row() {
          //   // 预览流设置缩放比例
          //   Button('缩放比例,当前比例:' + this.setZoomValue)
          //     .onClick(() => {
          //       // 设置相机缩放比例
          //       if (!this.isShowBack) {
          //         if (!this.zoomValue || this.zoomValue === this.setZoomValue) {
          //           this.setZoomValue = this.customGetZoom();
          //         } else {
          //           this.zoomValue = this.zoomValue;
          //           this.customSetZoom(this.zoomValue);
          //           setTimeout(() => {
          //             if (!this.isShowBack) {
          //               this.setZoomValue = this.customGetZoom();
          //             }
          //           }, 1000);
          //         }
          //       }
          //     })
          // }
          // .margin({ top: 10, bottom: 10 })
          //
          // Row() {
          //   // 输入要设置的预览流缩放比例
          //   TextInput({ placeholder: '输入缩放倍数' })
          //     .type(InputType.Number)
          //     .borderWidth(1)
          //     .backgroundColor(Color.White)
          //     .onChange(value => {
          //       this.zoomValue = Number(value);
          //     })
          // }
        }
        .width('50%')
        .height(180)
      }

      // 单码、多码扫描后，显示码图蓝点位置。点击toast码图信息
      ForEach(this.scanResult, (item: scanBarcode.ScanResult, index: number) => {
        if (item.scanCodeRect) {
          Image($rawfile('scan_selected2.svg'))
            .width(40)
            .height(40)
            .markAnchor({ x: 20, y: 20 })
            .position({
              x: (item.scanCodeRect.left + item?.scanCodeRect?.right) / 2 + this.offsetX,
              y: (item.scanCodeRect.top + item?.scanCodeRect?.bottom) / 2 + this.offsetY
            })
            .onClick(() => {
              this.showScanResult(item);
            })
        }
      })
    }
    // 建议相机流设置为全屏
    .width('100%')
    .height('100%')
    .onClick((event: ClickEvent) => {
      // 是否已扫描到结果
      if (this.isShowBack) {
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
      hilog.info(0x0001, TAG, `Succeeded in setting focusPoint x1: ${x1}, y1: ${y1}`);
      // 设置连续自动对焦模式
      setTimeout(() => {
        try {
          customScan.resetFocus();
        } catch (error) {
          hilog.error(0x0001, TAG, `Failed to reset Focus. Code: ${error.code}, message: ${error.message}`);
        }
      }, 200);
    }).gesture(PinchGesture({ fingers: 2 })
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
        if (this.isShowBack) {
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