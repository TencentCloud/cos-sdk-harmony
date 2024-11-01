import { CosXmlBaseService, DownloadTask, GetObjectRequest, HttpProgress } from '@tencentcloud/cos';
import { Const } from '../../Const';
import { CRC64 } from '../../utils/CRC64';
import { Logger } from '../../utils/Logger';
import { printError, sizeFormat } from '../../utils/Utils';

@Entry
@Component
export struct DownloadPage {
  @State filePath:string = getContext().filesDir + '/video.mp4';
  @State total:number = 0;
  @State value:number = 0;
  @State result:string = '';
  @State pause:boolean = true;
  currentTask?:DownloadTask;

  reset(){
    this.currentTask = undefined;
    this.pause = true;
  }

  _downloadFile(){
    this.reset();
    this.pause = false;
    let now = new Date().getTime() / 1000;
    let getRequest = new GetObjectRequest(Const.TEST_BUCKET, Const.TEST_DOWNLOAD_PATH, this.filePath);
    let task:DownloadTask = CosXmlBaseService.default().download(getRequest);
    task.onProgress = (progress:HttpProgress)=>{
      Logger.debug(`qqq total=${progress.target}   complete=${progress.complete}`)
      this.total = progress.target;
      this.value = progress.complete;
    };
    task.onResult = {
      onSuccess:async (request, result)=>{
        this.currentTask = undefined;

        // crc64计算比较慢，大文件不太适合
        // let fileHash = (await CRC64.crc64File(this.filePath)).toString();
        // let crc64ecma: string = "";
        // if(result.headers){
        //   crc64ecma = result.headers["x-cos-hash-crc64ecma"];
        // }
        // Logger.info(`crc64：本地文件crc64为${fileHash} x-cos-hash-crc64ecma为${crc64ecma}`)
        // if(fileHash === crc64ecma) {
        //   let finish = new Date().getTime() / 1000;
        //   this.result = '下载成功\n' + '下载平均速度：' + sizeFormat(this.total/((finish - now) || 1)) + '/S\n' + 'result\n' +  JSON.stringify(result,null,2) + '\n';
        //   this.pause = true;
        // } else {
        //   this.result = `下载失败:crc64校验失败`
        // }

        let finish = new Date().getTime() / 1000;
        this.result = '下载成功\n' + '下载平均速度：' + sizeFormat(this.total/((finish - now) || 1)) + '/S\n' + 'result\n' +  JSON.stringify(result,null,2) + '\n';
        this.pause = true;
      },
      onFail:(request, error)=>{
        this.result = `下载失败:
        ${printError(error)}`;
      }
    }
    task.start();
    this.result = "开始下载";
    this.currentTask = task;
  }

  scroller: Scroller = new Scroller()
  build() {
    Stack({ }) {
      Scroll(this.scroller){
        Column(){
          Row(){
            Text('cos 路径: ').fontSize(14)
              .align(Alignment.Start).textAlign(TextAlign.Start)
            Text(Const.TEST_DOWNLOAD_PATH).fontSize(14).fontWeight(FontWeight.Bold)
              .align(Alignment.Start).textAlign(TextAlign.Start).width('70%')
          }.margin({top:10,left:8,right:8})
          Row(){
            Text('本地路径: ').fontSize(14)
              .align(Alignment.Start).textAlign(TextAlign.Start)
            Text(this.filePath).fontSize(14).fontWeight(FontWeight.Bold)
              .align(Alignment.Start).textAlign(TextAlign.Start).width('70%')
          }.margin({top:6,left:8,right:8})

          Row(){
            Text('下载进度').fontSize(14)
              .align(Alignment.Start).textAlign(TextAlign.Start).margin({top:4,bottom:4,left:8,right:8})
            Progress({ value: this.value, total: this.total, type: ProgressType.Linear }).width('80%')
          }.margin({top:20})

          Flex({justifyContent: FlexAlign.SpaceEvenly}){
            Button(this.pause?'开始':'暂停', { type: ButtonType.Capsule, stateEffect: false })
              .onClick(()=>{
                if (this.pause) {
                  this._downloadFile();
                }else{
                  if (this.currentTask) {
                    this.currentTask?.pause();
                    this.pause = true;
                  }else{
                    this.result = '当前没有任务可暂停'
                  }
                }
              })
              .width(80)
              .height(40)

            Button('取消', { type: ButtonType.Capsule, stateEffect: false })
              .onClick(()=>{
                this.currentTask?.cancel();
                this.currentTask = undefined;
                this.pause = true;
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