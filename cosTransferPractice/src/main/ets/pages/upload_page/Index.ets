import { BusinessError } from '@ohos.base';
import picker from '@ohos.file.picker';
import { CosXmlBaseService, HttpProgress, PutObjectRequest, UploadTask } from '@tencentcloud/cos';
import { Const } from '../../Const';
import { sizeFormat } from '../../utils/Utils';

@Entry
@Component
export struct UploadPage {


  @State filePath?:string = undefined;
  @State total:number = 0;
  @State value:number = 0;
  @State result:string = '';
  @State pause:boolean = true;
  uploadId?:string = undefined;
  currentTask?:UploadTask;

  reset(){
    this.value = 0;
    this.total = 0;
    this.currentTask = undefined;
    this.pause = true;
    this.uploadId = undefined;
  }

  _selectPhoto(){
    try {
      let photoPicker = new picker.PhotoViewPicker();
      photoPicker.select((err: BusinessError, photoSelectResult: picker.PhotoSelectResult) => {
        if (err) {
          console.error('PhotoViewPicker.select failed with err: ' + JSON.stringify(err));
          return;
        }
        this.filePath = photoSelectResult.photoUris[0];
      });
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error('PhotoViewPicker failed with err: ' + JSON.stringify(err));
    }
  }

  _selectFile(){
    // let pathDir = getContext().tempDir;
    // let filePath = pathDir + "/tempFile";
    // let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    // let buffer:ArrayBuffer = new ArrayBuffer(1000 * 1024 * 1024);
    // let writeLen = fs.writeSync(file.fd, buffer);
    // console.info("write data to file succeed and size is:" + writeLen);
    // fs.closeSync(file);
    //
    // // let filePath = FileUtils.getFile(100 * 1024 * 1024);
    // let putReqeust = new PutObjectRequest('tinna-media-1253960454', `uploadTest/UT/bigUpload`, filePath);
    // let task: UploadTask = CosXmlBaseService.default().upload(putReqeust);
    // task.onProgress = (progress: HttpProgress) => {
    //   console.log(`bigUpload_onProgress：${progress.complete}/${progress.target}`,'CosSdkUT')
    // };
    // task.onResult = {
    //   onSuccess: (request, result) => {
    //     console.log(`bigUpload_success`,'CosSdkUT')
    //   },
    //   onFail: (request, error) => {
    //     console.log(`bigUpload_fail`,'CosSdkUT')
    //   }
    // }
    // task.start();

    try {
      let documentSelectOptions = new picker.DocumentSelectOptions();
      let documentPicker = new picker.DocumentViewPicker();
      documentPicker.select(documentSelectOptions).then((documentSelectResult: Array<string>) => {
        this.filePath = documentSelectResult[0];
      }).catch((err: BusinessError) => {
        console.error('DocumentViewPicker.select failed with err: ' + JSON.stringify(err));
      });
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error('DocumentViewPicker failed with err: ' + JSON.stringify(err))
    }
  }

  _uploadFile(){
    if (!this.filePath) {
      this.result = "请选择文件"
      return
    }
    this.pause = false;
    let now = new Date().getTime() / 1000;
    let paths = this.filePath?.split('/');
    let name = paths[paths.length - 1];
    let putReqeust = new PutObjectRequest(Const.TEST_BUCKET, Const.TEST_UPLOAD_DIR + name, this.filePath);
    let task:UploadTask = CosXmlBaseService.default().upload(putReqeust,this.uploadId);
    task.onProgress = (progress:HttpProgress)=>{
      this.total = progress.target;
      this.value = progress.complete;
    };
    task.onResult = {
      onSuccess:(request, result)=>{
        this.uploadId = undefined;
        this.currentTask = undefined;
        this.result = '上传成功\n' + 'result\n' +  JSON.stringify(result,null,2) + '\n';
        let finish = new Date().getTime() / 1000;
        this.result += '上传平均速度：' + sizeFormat(this.total/((finish - now) || 1)) + '/S'
        this.pause = true;
      },
      onFail:(request, error)=>{
        this.result = '上传失败\n' + 'error\n' +  error.message;
      }
    }
    task.initCallBack = (uploadId:string)=>{

      this.uploadId = uploadId;
    }
    task.start();
    this.result = "开始上传";
    this.currentTask = task;
  }

  scroller: Scroller = new Scroller()

  build() {
    Stack({ }) {
      Scroll(this.scroller){
        Column(){
          Flex({justifyContent: FlexAlign.SpaceEvenly}){
            Button('选择文件', { type: ButtonType.Capsule, stateEffect: false })
              .onClick(()=>{
                this._selectFile();
                this.reset()
              })
              .backgroundColor(0x317aff)
              .width(100)
              .height(40)
              .margin(10).fontSize(13)


            Button('选择图片', { type: ButtonType.Capsule, stateEffect: false })
              .onClick(()=>{
                // CosSdkUtils.singleUtils().uploadFile();
                this._selectPhoto();
                this.reset()
              })
              .backgroundColor(0x317aff)
              .width(100)
              .height(40)
              .margin(10).fontSize(13)
          }.margin(20)

          Row(){
            Text('本地文件路径:').fontSize(14)
              .onClick(()=>{
                console.info('我是Span——onClick')
              }).align(Alignment.Start).textAlign(TextAlign.Start).margin(8)
            Text(this.filePath).fontSize(14)
              .onClick(()=>{
                console.info('我是Span——onClick')
              }).align(Alignment.Start).textAlign(TextAlign.Start).padding(8).width('70%')
          }.margin({top:32})


          Row(){
            Text('进度').fontSize(14)
              .onClick(()=>{
                console.info('我是Span——onClick')
              }).align(Alignment.Start).textAlign(TextAlign.Start).margin({top:4,bottom:4,left:8,right:8})

            Progress({ value: this.value, total: this.total, type: ProgressType.Linear }).width('80%')
          }

          Flex({justifyContent: FlexAlign.SpaceEvenly}){
            Button(this.pause?'开始':'暂停', { type: ButtonType.Capsule, stateEffect: false })
              .onClick(()=>{
                if (this.pause) {
                  this._uploadFile();
                }else{
                  if (this.currentTask) {
                    this.currentTask?.pause();
                    this.pause = true;
                  }else{
                    this.result = '当前没有任务可暂停'
                  }
                }
                // CosSdkUtils.singleUtils().uploadFile()
              }).backgroundColor(0x317aff)
              .width(80)
              .height(40)

            Button('取消', { type: ButtonType.Capsule, stateEffect: false })
              .onClick(()=>{
                this.currentTask?.cancel();
                this.currentTask = undefined;
                this.pause = true;
              })
              .backgroundColor(0x317aff)
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