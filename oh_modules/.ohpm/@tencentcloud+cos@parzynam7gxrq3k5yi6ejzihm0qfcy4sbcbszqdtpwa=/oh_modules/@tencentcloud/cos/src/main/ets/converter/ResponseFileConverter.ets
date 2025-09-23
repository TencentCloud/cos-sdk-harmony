import { HttpHeader, HttpProgress, HttpRequest, HttpUtils, ProgressController } from '@tencentcloud/foundation';
import { CosXmlResult } from '../model/CosXmlResult';
import { CosResponseBodyConverter } from './CosResponseBodyConverter';
import fs from '@ohos.file.fs';
import { Range } from '../common/Range';
import { ContentType } from '@tencentcloud/foundation';

// 和GetObjectRequest强绑定 也就是说目前只用于GetObjectRequest
export class ResponseFileConverter<T> extends CosResponseBodyConverter<T> {
  private filePath: string;
  private fileOffset: number = 0;
  private cosXmlResult: CosXmlResult;
  private progressController: ProgressController;
  private file?: fs.File;
  // 重试修改range前已经下载的长度
  private lastTimeBytes: number = 0;
  // 已传输的数据长度
  private bytesTotal: number = 0;

  constructor(filePath: string, fileOffset: number, cosXmlResult: CosXmlResult, progressGranularity: number, onProgress?:Callback<HttpProgress>) {
    super();
    this.filePath = filePath;
    this.fileOffset = fileOffset;
    this.cosXmlResult = cosXmlResult;
    this.progressController = new ProgressController(onProgress, progressGranularity);
  }

  // 拿到header 因为http状态码最后才能拿到 需要跟进content type判断文件写入等
  private contentType = "";
  header?: Record<string, string>;
  private contentLength: number = 0;
  headersReceive(header: Record<string, string>): void {
    this.header = header;
    this.contentType = header[HttpHeader.RESPONSE_CONTENT_TYPE];

    let contentRangeString = header[HttpHeader.CONTENT_RANGE];
    let contentRange = HttpUtils.parseContentRange(contentRangeString);
    if (contentRange) {
      //206
      this.contentLength = contentRange[1] - contentRange[0] + 1;
    } else {
      //200
      this.contentLength = Number(header[HttpHeader.CONTENT_LENGTH]);
    }
  }

  buffers: ArrayBuffer[] = [];
  convertPart(arrayBuffer: ArrayBuffer): void {
    // xml类型文件 需要先写文件 如果是服务端异常再进行文件清除
    if(this.contentType === ContentType.XML){
      this.buffers.push(arrayBuffer);
    }
    if(!this.file){
      const dirPath = this.getDirPath(this.filePath);
      if (!fs.accessSync(dirPath)) {
        fs.mkdirSync(dirPath, true);
      }

      this.file = fs.openSync(this.filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
    }
    this.bytesTotal += fs.writeSync(this.file.fd, arrayBuffer, {
      offset: this.bytesTotal + this.fileOffset,
    })
    if (this.progressController) {
      this.progressController.updateProgress(this.bytesTotal, this.contentLength+this.lastTimeBytes);
    }
  }

  convertEnd(httpCode: number): T {
    if(httpCode < 200 || httpCode >= 300){
      // 删除本地已写入的文件
      if(this.file){
        if (fs.accessSync(this.file.path)) {
          fs.unlinkSync(this.file.path)
        }
      }
    }

    if(this.file){
      fs.closeSync(this.file);
    }

    let arrayBuffer = this.concatenateArrayBuffers(...this.buffers);
    if(this.contentType === ContentType.XML){
      // xml响应 解析为服务端错误
      this.parseCosXmlError(httpCode, arrayBuffer, this.header);
    }
    this.cosXmlResult.parseResponseBody(httpCode, this.header!, arrayBuffer);
    return this.cosXmlResult as T;
  }

  reset(request:HttpRequest<T>) {
    if(this.file){
      let range = request.getHeader(HttpHeader.RANGE);
      let rangeEnd: number = -1;
      if (range) {
        let index2 = range.indexOf("-");
        let end = range.substring(index2 + 1);
        if (end.trim() !== "") {
          rangeEnd = Number(end);
        }
      }
      request.removeHeader(HttpHeader.RANGE);
      let fileSize = (fs.statSync(this.file.path)).size;
      request.addHeader(HttpHeader.RANGE, new Range(fileSize, rangeEnd).getRange());
      // 存储range改变前已下载的长度
      this.lastTimeBytes = this.bytesTotal;
    }
  }

  getDirPath(filePath: string): string {
    const parts = filePath.split('/');
    parts.pop();
    return parts.join('/');
  }
}