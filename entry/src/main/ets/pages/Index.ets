import WindowManager from '../utils/WindowManager';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  build() {
    Column() {
      Stack()
      .width("100%")
      .height("100%")
      .backgroundColor("#f4f4f4")
      .layoutWeight(1)
      .padding({ bottom: WindowManager.navBarHeight })


    }
    .width('100%')
    .height('100%')
  }
}