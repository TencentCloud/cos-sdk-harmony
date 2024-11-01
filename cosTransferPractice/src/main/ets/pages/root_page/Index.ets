import {UploadPage } from '../upload_page/Index'
import { DownloadPage } from '../download_page/Index'

@Entry
@Component
struct RootPage {

  @State currentIndex: number = 0

  controller: TabsController = new TabsController()

  @Builder tabBuilder(title: string, targetIndex: number) {
    Column() {
      Text(title)
        .fontColor(this.currentIndex === targetIndex ? '#1698CE' : '#6B6B6B').fontSize(13).margin(4)
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      Text("COS SDK Demo")
        .fontColor(Color.Black)
        .height('8%')
        .fontSize(26)
      Tabs({barPosition:BarPosition.End}){
        TabContent() {
          UploadPage()
            .width('100%')
            .height('100%')
            .backgroundColor('#f5f5f5')
        }
        .tabBar(this.tabBuilder('上传', 0))
        TabContent() {
          DownloadPage()
            .width('100%')
            .height('100%')
            .backgroundColor('#f5f5f5')
        }
        .tabBar(this.tabBuilder('下载', 1))
      }
      .animationDuration(0)
      .height('92%')
      .backgroundColor(Color.White)
      .onChange((index: number) => {
        this.currentIndex = index
      })
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Color.White)
  }
}
