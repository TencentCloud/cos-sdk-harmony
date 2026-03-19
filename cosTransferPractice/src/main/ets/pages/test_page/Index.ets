import { CosXmlBaseService, DownloadTask, GetObjectRequest, HttpProgress, CosXmlDownloadTaskResult, CosError,
  HeadObjectRequest } from '@tencentcloud/cos';
import { Const } from '../../Const';

@Entry
@Component
export struct TestPage {
  @State result:string = '';
  scroller: Scroller = new Scroller()
  build() {
    Stack({ }) {
      Scroll(this.scroller){
        Column(){
          Flex({justifyContent: FlexAlign.SpaceEvenly}){
            Button('获取数据', { type: ButtonType.Capsule, stateEffect: false })
              .onClick(async ()=>{
                this.result = "获取中......"
                try {
                  let headRequest = new HeadObjectRequest(Const.TEST_BUCKET, Const.TEST_DOWNLOAD_PATH);
                  let headResult = await CosXmlBaseService.default().headObject(headRequest)
                  this.result = "httpCode：" + headResult.httpCode
                } catch (e) {
                  console.log(e)
                  this.result = "error：" + e.message
                }
              })
              .width(80)
              .height(40)
          }.width('100%').margin({top:16})

          Text('结果:').fontSize(14).margin(8)
          Text(this.result).align(Alignment.TopStart).fontSize(14).backgroundColor('#eeeeee').width('100%').height('100%').padding(8)
        }.alignItems(HorizontalAlign.Start)

      }.width('100%').height(200).scrollable(ScrollDirection.Vertical).enableScrollInteraction(true)
      .backgroundColor('#FFF1F3F5')
      .height('100%').width('100%')
    }.width('100%').height('100%').align(Alignment.Bottom)
  }
}