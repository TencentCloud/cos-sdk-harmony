import { PutObjectRequest } from '../model/object/PutObjectRequest';
import { kSliceLength, TransferConfig } from './TransferConfig';
import fs, { ReadOptions } from '@ohos.file.fs';
import { TransferState, TransferTask } from './TransferTask';
import { CosXmlBaseService } from '../CosXmlBaseService';
import { InitMultipartUploadRequest } from '../model/object/InitMultipartUploadRequest';
import { InitMultipartUploadResult } from '../model/object/InitMultipartUploadResult';
import { FilePartInfo, UploadPartRequest } from '../model/object/UploadPartRequest';
import { ListPartsRequest } from '../model/object/ListPartsRequest';
import { ListPartsPart, ListPartsResult } from '../model/object/ListPartsResult';
import {
  CompleteMultipartUpload,
  CompleteMultipartUploadPart,
  CompleteMultiUploadRequest
} from '../model/object/CompleteMultiUploadRequest';
import List from '@ohos.util.List';
import { ContentType, HttpProgress, HttpHeader, QCloudUserCancelError } from '@tencentcloud/foundation';
import { CosXmlRequest } from '../model/CosXmlRequest';
import { CompleteMultipartUploadResult, CompleteMultiUploadResult } from '../model/object/CompleteMultiUploadResult';
import { Callback } from '@ohos.base';
import { AbortMultiUploadRequest } from '../model/object/AbortMultiUploadRequest';
import { PicUploadResult, PutObjectResult } from '../model/object/PutObjectResult';
import { CosInvalidArgumentError } from '../error/CosInvalidArgumentError';
import { CosClientError } from '../error/CosClientError';
import { QCloudPriority } from '@tencentcloud/foundation';
import { CosTransferPauseError } from '../error/CosTransferPauseError';
import { CosErrorCode } from '../error/CosErrorCode';
import { CosXmlResult } from '../model/CosXmlResult';
import { PicOriginalInfo } from '../model/pic/PicOriginalInfo';

/**
 * 上传任务
 *
 * 功能概述：
 *    提供了将文件上传到腾讯云对象存储（COS）存储桶的功能。包括简单上传和分块上传两种方式。具体的接口说明可以参考腾讯云的文档：
 *    简单上传（https://cloud.tencent.com/document/product/436/7753）分块上传（https://cloud.tencent.com/document/product/436/34904）。
 *    根据上传文件的类型和大小，代码内部会自动选择使用简单上传还是分块上传：
 *    分块上传：当上传文件为文件路径且文件大小大于等于1M时，会使用分块上传。分块上传是将文件分割成多个块进行上传的方式。（由构造方法中 TransferConfig->simpleUploadLimit参数配置，默认1M）
 *    简单上传：当上传文件为ArrayBuffer类型或文件大小小于1M时，会使用简单上传。简单上传是将整个文件一次性上传的方式。
 *
 *    此外，代码还支持任务的暂停、续传和取消功能。如果需要实现断点续传功能，需要在业务中保存 initCallback 方法返回的 uploadId。
 *
 * 示例代码：
 *
 *    // 实例化 PutObjectRequest，设置存储桶名、目标路径，本地文件。
 *    // 存储桶名称：由BucketName-Appid 组成，可以在COS控制台查看 https://console.cloud.tencent.com/cos5/bucket
 *    // 上传目标路径：是对象在 COS 上的完整路径，如果带目录的话，格式为 "video/xxx/movie.mp4"
 *    // 本地文件：文件路径或ArrayBuffer。
 *    let putRequest = new PutObjectRequest("存储桶名称", "上传目标路径", "本地文件");
 *
 *    // 使用 CosXmlBaseService 服务实例调用 upload 方法，获取当前上传任务 task；CosXmlBaseService具体使用方法，请参考 CosXmlBaseService。
 *    // uploadId：可选参数，用于续传。
 *    let task:UploadTask = CosXmlBaseService.default().upload(putReqeust,"uploadId");
 *
 *    // 设置initCallBack ，获取分块上传 uploadId （简单上传不返回uploadId）
 *    task.initCallBack = (uploadId:string)=>{
 *      this.uploadId = uploadId;
 *    }
 *    // 设置上传进度回调
 *    task.onProgress = (progress: HttpProgress) => {
 *      complete：已发送的字节数
 *      target：本次上传要发送的总字节数（即一个文件大小）
 *    };
 *
 *    // 设置完成回调
 *    task.onResult = {
 *      // 成功回调
 *      onSuccess: (request, result) => {
 *          // request：当前请求request
 *          // resultL：响应结果
 *      },
 *      // 失败回调
 *      onFail: (request, error) => {
 *          // request：当前请求request
 *          // error：错误信息
 *      }
 *    }
 *    task.start()
 *
 *
 * 暂停任务、继续任务、取消任务
 *    暂停：暂停当前任务，不会清空已上传的文件。
 *    task.pause();
 *
 *    继续：重新启动暂停的任务。
 *    task.resume();
 *
 *    取消：取消当前上传任务，会删除已上传的临时文件
 *    task.cancel();
 *
 * 退出进程实现断点上传
 *    需业务测保存 uploadId，并在上传时传入，既可实现断点续传。
 *
 * 注意事项：
 *    简单上传、不返回uploadId，也不支持续传，暂停后会从0开始上传。
 */
export class UploadTask extends TransferTask<PutObjectRequest, CosXmlUploadTaskResult> {
  requestCacheArray: List<CosXmlRequest> = new List();
  uploadId?: string;
  config: TransferConfig;
  request: PutObjectRequest;
  uploadedParts: List<CompleteMultipartUploadPart> = new List();
  currentSuccessParts: List<CompleteMultipartUploadPart> = new List();
  isChange: boolean = false;
  private fileTotalSize: number = 0;
  private uploadedSize: number = 0;
  private startPartNumber: number = 0;
  private uploadBodyIsCompleted: boolean = false;
  private state = TransferState.Waiting;

  private updateState(state: TransferState) {
    this.state = state;
    // if (this.onState) {
    //   this.onState(this.state);
    // }
  }

  public initCallBack: Callback<string> | undefined;

  constructor(cosXmlBaseService: CosXmlBaseService, request: PutObjectRequest, uploadId?: string,
    config?: TransferConfig) {
    super(cosXmlBaseService, request);
    if (uploadId) {
      this.uploadId = uploadId;
    }
    if (config) {
      this.config = config;
    } else {
      this.config = new TransferConfig();
    }

    this.request = request;
  }

  start(): void {
    try {
      this.executeTask()
      this.updateState(TransferState.Processing);
    } catch (e) {
      this.onFail(this.request, e);
    }
  }

  pause(): void {
    try {
      this.onFail(this.request, new CosTransferPauseError())
      this.updateState(TransferState.Pause);
      this.cancelRequest();
    } catch (e) {
      this.onFail(this.request, e);
    }
  }

  resume(): void {
    if (this.uploadId) {
      try {
        this.resumeUpload(this.uploadId);
        this.updateState(TransferState.Processing);
      } catch (e) {
        this.onFail(this.request, e);
      }
    } else {
      this.onFail(this.request, new CosInvalidArgumentError("Upload Id is empty, upload resumption failed"));
    }
  }

  async cancel() {
    if (this.state == TransferState.Success || this.state == TransferState.Error ||
      this.state == TransferState.Canceled) {
      return;
    }

    try {
      if (this.uploadId) {
        let request = new AbortMultiUploadRequest(this.request.bucket!, this.request.cosPath, this.uploadId!);
        request.credential = this.request.credential;
        request.addHeaders(this.request.getHeaders());
        request.addQueries(this.request.getQueries());
        request.addNoSignHeaderKeys(this.request.noSignHeaderKeys);
        request.addNoSignQueryKeys(this.request.noSignQueryKeys);
        request.priority = QCloudPriority.High;
        try {
          await this.cosXmlBaseService.abortMultiUpload(request);
        } catch (e) {
        }
      }
      this.onFail(this.request, new QCloudUserCancelError())
      this.updateState(TransferState.Canceled);
      this.cancelRequest();
    } catch (e) {
      this.onFail(this.request, e);
    }
  }

  cancelRequest() {
    this.requestCacheArray.forEach((request) => {
      this.cosXmlBaseService.cancel(request);
    });
  }

  public executeTask() {
    if (!this.request.body) {
      this.onFail(this.request, new CosInvalidArgumentError('Upload file cannot be empty'));
      this.updateState(TransferState.Error);
      return;
    }

    if (typeof this.request.body == 'string') {
      let file = fs.openSync(this.request.body);
      let stat = fs.statSync(file.fd);
      this.fileTotalSize = stat.size;
      fs.closeSync(file.fd);
      if (stat.size >= this.config.simpleUploadLimit) {
        this.partUpload();
      } else {
        this.simpleUpload();
      }
    } else if (this.request.body instanceof ArrayBuffer) {
      this.fileTotalSize = this.request.body.byteLength;
      this.simpleUpload();
    } else {
      this.onFail(this.request, new CosInvalidArgumentError("Unsupported upload type"));
      this.updateState(TransferState.Error);
      this.cancelRequest();
    }
  }

  private async simpleUpload() {
    let request: PutObjectRequest = new PutObjectRequest(this.request.bucket!, this.request.cosPath, this.request.body);
    request.credential = this.request.credential;
    request.addHeaders(this.request.getHeaders());
    request.addQueries(this.request.getQueries());
    request.addNoSignHeaderKeys(this.request.noSignHeaderKeys);
    request.addNoSignQueryKeys(this.request.noSignQueryKeys);
    request.onProgress = this.onProgress;
    try {
      this.requestCacheArray.add(request);
      let result: PutObjectResult = await this.cosXmlBaseService.putObject(request);
      this.updateState(TransferState.Success);
      this.onSuccess(this.request, this.buildCosXmlTaskResult(result));
      this.requestCacheArray.clear();
    } catch (e) {
      this.onFail(this.request, e);
      this.updateState(TransferState.Error);
      this.cancelRequest();
    }
  }

  private partUpload() {
    if (this.uploadId) {
      this.resumeUpload(this.uploadId);
    } else {
      this.initPartUpload();
    }
  }

  private async resumeUpload(uploadId: string) {
    try {
      let result = await this.listParts(uploadId);
      if (this.initCallBack) {
        this.initCallBack(uploadId);
      }
      this.continueMultiUpload(result);
    } catch (e) {
      this.initPartUpload();
    }
  }

  private async listParts(uploadId: string): Promise<ListPartsResult> {
    let result: ListPartsResult = new ListPartsResult;
    let exitParts: List<ListPartsPart> = new List();
    do {
      let request = new ListPartsRequest(this.request.bucket!, this.request.cosPath, uploadId);
      request.credential = this.request.credential;
      request.priority = QCloudPriority.High;
      request.partNumberMarker = result?.listParts?.nextPartNumberMarker;
      request.addHeaders(this.request.getHeaders());
      request.removeHeader(HttpHeader.CONTENT_TYPE)
      request.removeHeader(HttpHeader.CONTENT_LENGTH)
      request.addQueries(this.request.getQueries());
      request.addNoSignHeaderKeys(this.request.noSignHeaderKeys);
      request.addNoSignQueryKeys(this.request.noSignQueryKeys);
      this.requestCacheArray.add(request);
      result = await this.cosXmlBaseService.listParts(request);
      if (result && result.listParts && result.listParts.part) {
        result.listParts.part.forEach((item) => {
          exitParts.add(item);
        })
      }
    } while (result?.listParts?.isTruncated === true && result?.listParts?.nextPartNumberMarker &&
      result?.listParts?.nextPartNumberMarker?.length > 0)
    result.listParts?.setPart(exitParts);
    return result;
  }

  private continueMultiUpload(result: ListPartsResult) {
    this.uploadedParts = new List();
    let allparts = this.getFileLocalUploadParts();
    let existMap = new Map<string, ListPartsPart>()
    for (const item of result.listParts?.part || []) {
      existMap.set(item.partNumber, item);
    }

    let resetParts = new List<FilePartInfo>();
    for (const offsetBody of allparts) {
      let key: string = (offsetBody.index + 1).toString();
      let part = existMap.get(key);
      if (!part) {
        resetParts.add(offsetBody)
      } else {
        if (parseInt(part.size) != offsetBody.length) {
          this.isChange = true;
          break;
        }
        this.uploadedSize += offsetBody.length;
        let info = new CompleteMultipartUploadPart(parseInt(part.partNumber), part.eTag);
        this.uploadedParts.add(info);
      }
    }
    if (!this.isChange) {
      if (resetParts.length == 0) {
        this.finishUpload(this.uploadId!);
      } else {
        this.uploadOffsetBodys(resetParts);
      }
    } else {
      this.uploadedSize = 0;
      this.getContinueInfo(result.listParts?.part!);
      if (this.uploadedSize == this.fileTotalSize) {
        this.finishUpload(this.uploadId!);
      } else {
        this.uploadOffsetBodys(this.getFileLocalUploadParts());
      }
    }
  }

  private getContinueInfo(existParts: List<ListPartsPart>) {

    this.uploadedParts = new List();
    let i = 1;
    let part = existParts.get(0);
    let info = new CompleteMultipartUploadPart(parseInt(part.partNumber), part.eTag);
    if (info.partNumber != 1) {
      return;
    }
    for (i = 0; i < existParts.length; i++) {
      let part1 = existParts.get(i);
      let info1 = new CompleteMultipartUploadPart(parseInt(part1.partNumber), part1.eTag);
      this.uploadedSize += parseInt(part1.size);
      this.uploadedParts.add(info1);

      if (i == existParts.length - 1) {
        break;
      }

      let part2 = existParts.get(+1);
      if (parseInt(part1.partNumber) + 1 != parseInt(part2.partNumber)) {
        break;
      }
    }
    this.startPartNumber = this.uploadedParts.length;
  }

  private async initPartUpload() {
    let request = new InitMultipartUploadRequest(this.request.bucket!, this.request.getPath());
    request.credential = this.request.credential;
    request.priority = QCloudPriority.High;
    request.addHeaders(this.request.getHeaders());
    request.addQueries(this.request.getQueries());
    request.addNoSignHeaderKeys(this.request.noSignHeaderKeys);
    request.addNoSignQueryKeys(this.request.noSignQueryKeys);
    this.requestCacheArray.add(request);
    try {
      let result: InitMultipartUploadResult = await this.cosXmlBaseService.initMultipartUpload(request);
      if (!result.initMultipartUpload?.uploadId) {
        this.onFail(this.request, new CosClientError(CosErrorCode.DATA_FORMAT, 'Failed to init multipart upload'));
        this.cancelRequest();
        return;
      }
      if (this.initCallBack) {
        this.initCallBack(result.initMultipartUpload?.uploadId);
      }
      this.uploadParts(result);
    } catch (e) {
      this.onFail(this.request, e);
      this.updateState(TransferState.Error);
      this.cancelRequest();
    }
  }

  private uploadParts(initInfo: InitMultipartUploadResult) {
    this.uploadId = initInfo.initMultipartUpload?.uploadId;
    let parts = this.getFileLocalUploadParts();
    this.uploadOffsetBodys(parts)
  }

  private uploadOffsetBodys(allParts: List<FilePartInfo>) {
    let stateSet = new Map<string, number>();
    for (const body of allParts) {
      stateSet.set(body.index.toString(), 0);
    }

    for (const body of allParts) {
      let request =
        new UploadPartRequest(this.request.bucket!, this.request.cosPath, this.uploadId!, (body.index + 1).toString(),
          body);
      request.credential = this.request.credential;
      request.addHeaders(this.request.getHeaders());
      request.removeHeader(HttpHeader.CONTENT_TYPE)
      request.removeHeader(HttpHeader.CONTENT_LENGTH)
      request.addQueries(this.request.getQueries());
      request.addNoSignHeaderKeys(this.request.noSignHeaderKeys);
      request.addNoSignQueryKeys(this.request.noSignQueryKeys);
      this.requestCacheArray.add(request);

      request.onProgress = (progress) => {
        if (this.onProgress && (this.state != TransferState.Error && this.state != TransferState.Pause)) {
          stateSet.set(body.index.toString(), progress.complete);
          let completes = stateSet.values();
          let total = 0;
          for (let completesElement of completes) {
            total += completesElement;
          }
          this.onProgress(new HttpProgress(this.uploadedSize + total, this.fileTotalSize));
        }
      };
      request.onSuccess = (response) => {
        stateSet.delete(body.index.toString());
        this.uploadedSize += body.length;
        let headers = response!.headers;
        if (headers) {
          let etag = headers[HttpHeader.ETAG];
          let info = new CompleteMultipartUploadPart(parseInt((body.index + 1).toString()), etag);
          this.uploadedParts.add(info);
        }

        if (stateSet.size == 0) {
          this.finishUpload(this.uploadId!);
        }
        this.requestCacheArray.remove(request);
      };
      request.onFailure = (err: Error) => {
        if (this.state != TransferState.Error && this.state != TransferState.Pause) {
          this.onFail(this.request, err);
          this.updateState(TransferState.Error);
          this.cancelRequest();
        }
      };

      this.cosXmlBaseService.partUpload(request);
    }
  }


  private async finishUpload(uploadId: string) {
    let request = new CompleteMultiUploadRequest(this.request.bucket!, this.request.cosPath, uploadId);
    request.credential = this.request.credential;
    request.priority = QCloudPriority.High;
    request.addHeaders(this.request.getHeaders());
    request.removeHeader(HttpHeader.CONTENT_TYPE)
    request.removeHeader(HttpHeader.CONTENT_LENGTH)
    request.addQueries(this.request.getQueries());
    request.addNoSignHeaderKeys(this.request.noSignHeaderKeys);
    request.addNoSignQueryKeys(this.request.noSignQueryKeys);
    this.uploadedParts.sort((obj1: CompleteMultipartUploadPart, obj2: CompleteMultipartUploadPart) => {
      if (obj1.partNumber < obj2.partNumber) {
        return -1;
      } else {
        return 1;
      }
    })

    let completeInput = new CompleteMultipartUpload();
    completeInput.part = this.uploadedParts;
    request.completeMultipartUpload = completeInput;

    try {
      let result = await this.cosXmlBaseService.completeMultiUpload(request);
      this.onSuccess(this.request, this.buildCosXmlTaskResult(result));
      this.updateState(TransferState.Success);
      this.requestCacheArray.clear();
    } catch (e) {
      this.onFail(this.request, e);
      this.updateState(TransferState.Error);
      this.cancelRequest();
    }
  }

  private getFileLocalUploadParts() {
    let allParts: List<FilePartInfo> = new List();
    let resetContentLength = this.fileTotalSize - this.uploadedSize;
    let offest = this.uploadedSize;
    for (let i = this.startPartNumber;; i++) {

      let slice = 0;
      let maxSlice = Math.ceil(this.fileTotalSize * 1.0 / 10000);
      let uploadSliceLength = this.config.sliceLength > 10 ? this.config.sliceLength : kSliceLength;
      uploadSliceLength = this.fileTotalSize * 1.0 / uploadSliceLength > 10000 ? maxSlice : uploadSliceLength;
      if (resetContentLength >= uploadSliceLength) {
        slice = uploadSliceLength;
      } else {
        slice = resetContentLength;
      }
      if (this.uploadBodyIsCompleted && slice < kSliceLength) {
        break;
      }
      if (typeof this.request.body == 'string' || typeof this.request.body == 'number') {
        let body: string | number = this.request.body;
        let part = new FilePartInfo(slice, offest, body);
        allParts.add(part);
        offest += slice;
        part.index = i;
        resetContentLength -= slice;
        if (resetContentLength <= 0) {
          break;
        }
      }
    }
    return allParts;
  }

  private buildCosXmlTaskResult(sourceResult: CosXmlResult): CosXmlUploadTaskResult {
    let cosXmlUploadTaskResult = new CosXmlUploadTaskResult();
    if (sourceResult) {
      cosXmlUploadTaskResult.httpCode = sourceResult.httpCode;
      cosXmlUploadTaskResult.headers = sourceResult.headers;
      cosXmlUploadTaskResult.accessUrl = sourceResult.accessUrl;
    }
    if (sourceResult instanceof PutObjectResult) {
      cosXmlUploadTaskResult.eTag = sourceResult.eTag();
      cosXmlUploadTaskResult.picUploadResult = sourceResult.picUploadResult;
    } else if (sourceResult instanceof CompleteMultiUploadResult) {
      cosXmlUploadTaskResult.eTag = sourceResult.result?.eTag;
      // 下面这行代码居然调不通（is not callable）  神奇的js
      // cosXmlUploadTaskResult.picUploadResult = sourceResult.result?.getPicUploadResult();

      if (sourceResult.result) {
        let picOriginalInfo = new PicOriginalInfo();
        picOriginalInfo.location = sourceResult.result.location;
        picOriginalInfo.key = sourceResult.result.key;
        picOriginalInfo.eTag = sourceResult.result.eTag;
        picOriginalInfo.imageInfo = sourceResult.result.imageInfo;
        let picUploadResult = new PicUploadResult();
        picUploadResult.originalInfo = picOriginalInfo;
        picUploadResult.processResults = sourceResult.result.processResults;
        cosXmlUploadTaskResult.picUploadResult = picUploadResult;
      }
    }
    return cosXmlUploadTaskResult;
  }
}

export class CosXmlUploadTaskResult extends CosXmlResult {
  public eTag?: string;
  public picUploadResult?: PicUploadResult;
}