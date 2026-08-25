import {UploadPage } from '../upload_page/Index'
import { DownloadPage } from '../download_page/Index'
import { CosServiceHelper } from '../../utils/CosServiceHelper'

@Entry
@Component
struct RootPage {

  @State currentIndex: number = 0
  // 自定义网络层开关，双向绑定 AppStorage
  @StorageLink('useCustomNetwork') useCustomNetwork: boolean = false

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
      // 自定义网络层开关：打开走自定义网络层(@ohos.net.http)，关闭走默认网络层(rcp)
      Row() {
        Text(this.useCustomNetwork ? '网络层：自定义 (@ohos.net.http)' : '网络层：默认 (rcp)')
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.useCustomNetwork })
          .onChange((isOn: boolean) => {
            // 切换后重新初始化默认服务，后续请求即走新的网络层
            CosServiceHelper.initDefaultService(getContext(this).getApplicationContext(), isOn)
          })
      }
      .width('92%')
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
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
      .height('84%')
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
