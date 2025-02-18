import { HttpHeader, HttpProgress, HttpUtils, QCloudLogger, QCloudUserCancelError } from '@tencentcloud/foundation';
import { CosXmlBaseService } from '../CosXmlBaseService';
import { GetObjectRequest } from '../model/object/GetObjectRequest';
import { TransferTask } from './TransferTask';
import dataPreferences from '@ohos.data.preferences';
import { HeadObjectRequest } from '../model/object/HeadObjectRequest';
import { CosXmlResult } from '../model/CosXmlResult';
import { CryptoUtil } from '@tencentcloud/foundation';
import fs from '@ohos.file.fs';
import { CosTransferPauseError } from '../error/CosTransferPauseError';

/**
 * 下载任务
 *
 * 功能概述：
 *    提供了将 cos 存储桶的文件下载到本地，并支持断点下载。
 *    具体 接口说明请参考：简单上传（https://cloud.tencent.com/document/product/436/7753）
 *
 * 示例代码：
 *
 *    // 实例化 GetObjectRequest，设置存储桶名、cos 文件路径、本地路径。
 *    // 存储桶名称：由BucketName-Appid 组成，可以在COS控制台查看 https://console.cloud.tencent.com/cos5/bucket
 *    // cos 文件路径，是对象在 COS 上的完整路径，如果带目录的话，格式为 "video/xxx/movie.mp4"
 *    // 本地路径：设置下载的路径 URL，如果设置了，文件将会被下载到指定路径中。
 *    let getRequest = new GetObjectRequest("存储桶名称", "cos 文件路径", "本地路径");
 *
 *    // 使用 CosXmlBaseService 服务实例调用 download 方法，获取当前下载任务 task；CosXmlBaseService具体使用方法，请参考 CosXmlBaseService。
 *    let task:DownloadTask = CosXmlBaseService.default().download(getRequest);
 *
 *    // 设置下载进度回调
 *    task.onProgress = (progress: HttpProgress) => {
 *      complete：已下载的字节数
 *      target：本次下载要接收的总字节数（即一个文件大小）
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
 *    // 启动任务。
 *    task.start()
 *
 * 暂停任务、继续任务、取消任务
 *    暂停：暂停当前任务，不会删除已下载的文件。
 *    task.pause();
 *
 *    继续：重新启动暂停的任务。
 *    task.resume();
 *
 *    取消：取消当前下载任务，会删除本地已下载的文件
 *    task.cancel();
 *
 * 退出进程实现断点下载
 *    开始下载时，传入和之前相同的本地路径，既可实现断点下载，SDK 内持久化存储暂停前的进度。
 *
 */

export class DownloadTask extends TransferTask<GetObjectRequest, CosXmlDownloadTaskResult> {
  private localSavePath: string;
  private fileOffset: number = 0;
  private rangeStart: number = 0;
  private rangeEnd: number = -1;
  private eTag: string | undefined;
  private hasWriteDataLen: number = 0;
  private request: GetObjectRequest;
  private headObjectRequest: HeadObjectRequest | undefined;
  private getObjectRequest: GetObjectRequest | undefined;
  private preferences: dataPreferences.Preferences;

  constructor(context: Context, cosXmlBaseService: CosXmlBaseService, request: GetObjectRequest) {
    super(cosXmlBaseService, request);
    this.request = request;
    this.fileOffset = request.fileOffset;
    this.localSavePath = request.filePath;
    QCloudLogger.log(`localSavePath:${this.localSavePath}, fileOffset:${this.fileOffset}`)

    //需要取出range字段
    let range = request.getHeaders().get(HttpHeader.RANGE);
    if (range) {
      let index1 = range.indexOf("=");
      let index2 = range.indexOf("-");
      this.rangeStart = Number(range.substring(index1 + 1, index2));
      let end = range.substring(index2 + 1);
      if (end.trim() !== "") {
        this.rangeEnd = Number(end);
      }
    }
    let options: dataPreferences.Options = { name: 'COSSDK_DownloadTask' };
    this.preferences = dataPreferences.getPreferencesSync(context, options);
  }


  start(): void {
    try {
      this.headObject();
    } catch (e) {
      this.onFail(this.request, e);
    }
  }

  pause(): void {
    try {
      this.onFail(this.request, new CosTransferPauseError())
      this.cancelAllRequest();
    } catch (e) {
      this.onFail(this.request, e);
    }
  }

  resume(): void {
    try {
      this.start();
    } catch (e) {
      this.onFail(this.request, e);
    }
  }

  async cancel(): Promise<void> {
    try {
      this.cancelAllRequest();
      await this.clear();
      this.onFail(this.request, new QCloudUserCancelError())
    } catch (e) {
      this.onFail(this.request, e);
    }
  }

  private async headObject() {
    this.headObjectRequest = new HeadObjectRequest(this.objectRequest.bucket!, this.objectRequest.cosPath);
    this.headObjectRequest.addHeaders(this.objectRequest.getHeaders());
    this.headObjectRequest.addQueries(this.objectRequest.getQueries());
    this.headObjectRequest.addNoSignHeaderKeys(this.objectRequest.noSignHeaderKeys);
    this.headObjectRequest.addNoSignQueryKeys(this.objectRequest.noSignQueryKeys);
    this.headObjectRequest.credential = this.objectRequest.credential;

    let contentLength: string | undefined;
    this.headObjectRequest.onHeaderReceive = (header: Record<string, string>) => {
      this.eTag = header[HttpHeader.ETAG];
      contentLength = header[HttpHeader.CONTENT_LENGTH];
    }
    try {
      let headObjectResult = await this.cosXmlBaseService.headObject(this.headObjectRequest);
      let absolutePath = await this.hasExisted();
      if (absolutePath) {
        if (await fs.access(this.localSavePath)) {
          let fileLength = (await fs.stat(this.localSavePath)).size;
          if (contentLength && Number(contentLength) === fileLength) {
            let onProgress = this.onProgress;
            if (onProgress) {
              onProgress(new HttpProgress(fileLength, fileLength));
            }
            this.onSuccess(this.request, this.buildCosXmlTaskResult(headObjectResult));
            await this.clear();
            return;
          } else {
            this.hasWriteDataLen = fileLength - this.fileOffset;
            this.realDownload(this.rangeStart + this.hasWriteDataLen, this.rangeEnd,
              this.fileOffset + this.hasWriteDataLen);
            return;
          }
        }
      }
      // 第一次下载文件，会先删除本地文件
      if (await fs.access(this.localSavePath)) {
        await fs.unlink(this.localSavePath)
      }
      await this.save(this.localSavePath); // 第一次下载
      this.hasWriteDataLen = 0;
      this.realDownload(this.rangeStart, this.rangeEnd, this.fileOffset);
    } catch (err) {
      this.onFail(this.request, err)
      this.cancelAllRequest();
    }
  }

  private async realDownload(rangeStart: number, rangeEnd: number, fileOffset: number) {
    this.getObjectRequest =
      new GetObjectRequest(this.objectRequest.bucket!, this.objectRequest.cosPath, this.localSavePath);
    this.getObjectRequest.fileOffset = fileOffset;
    this.getObjectRequest.addHeaders(this.objectRequest.getHeaders());
    this.getObjectRequest.addQueries(this.objectRequest.getQueries());
    this.getObjectRequest.addNoSignHeaderKeys(this.objectRequest.noSignHeaderKeys);
    this.getObjectRequest.addNoSignQueryKeys(this.objectRequest.noSignQueryKeys);
    if (rangeEnd > 0 || rangeStart > 0) {
      this.getObjectRequest.setRange(rangeStart, rangeEnd);
      //下载重试时会改变request的range，因此不能让range参与签名
      this.getObjectRequest.addNoSignHeaderKey(HttpHeader.RANGE);
    }
    this.getObjectRequest.credential = this.objectRequest.credential;
    this.getObjectRequest.onProgress = (httpProgress: HttpProgress) => {
      let onProgress = this.onProgress;
      if (onProgress) {
        onProgress(new HttpProgress(httpProgress.complete + fileOffset, httpProgress.target + fileOffset));
      }
    }
    try {
      let getObjectResult = await this.cosXmlBaseService.getObject(this.getObjectRequest);
      this.onSuccess(this.request, this.buildCosXmlTaskResult(getObjectResult));
      await this.clear();
    } catch (err) {
      this.onFail(this.request, err)
      this.cancelAllRequest();
    }
  }

  protected buildCosXmlTaskResult(sourceResult: CosXmlResult): CosXmlDownloadTaskResult {
    let cosXmlDownloadTaskResult = new CosXmlDownloadTaskResult();
    if (sourceResult) {
      cosXmlDownloadTaskResult.httpCode = sourceResult.httpCode;
      cosXmlDownloadTaskResult.headers = sourceResult.headers;
      cosXmlDownloadTaskResult.eTag = this.eTag;
      cosXmlDownloadTaskResult.accessUrl = sourceResult.accessUrl;
    }
    return cosXmlDownloadTaskResult;
  }

  private async getTaskKey(): Promise<string> {
    let stringBuffer = `download_
                        ${this.cosXmlBaseService.cosXmlServiceConfig.region}_
                        ${this.objectRequest.bucket}_
                        ${this.objectRequest.cosPath}_
                        ${this.rangeStart}_
                        ${this.rangeEnd}_
                        ${this.fileOffset}_
                        ${this.localSavePath}_
                        ${this.eTag}`;
    return await CryptoUtil.qlcoudSha1(stringBuffer);
  }

  private async hasExisted(): Promise<string | undefined> {
    let taskKey = await this.getTaskKey();
    if (await this.preferences.has(taskKey)) {
      let filePath = await this.preferences.get(taskKey, "");
      return filePath.toString();
    } else {
      return undefined;
    }
  }

  private async clear() {
    let taskKey = await this.getTaskKey();
    await this.preferences.delete(taskKey);
    await this.preferences.flush();
  }

  private async save(filePath: string) {
    let taskKey = await this.getTaskKey();
    await this.preferences.put(taskKey, filePath);
    await this.preferences.flush();
  }

  private cancelAllRequest() {
    if (this.headObjectRequest) {
      let headRequest = this.headObjectRequest;
      this.cosXmlBaseService.cancel(headRequest)
    }

    if (this.getObjectRequest) {
      let getRequest = this.getObjectRequest;
      this.cosXmlBaseService.cancel(getRequest)
    }
  }
}

export class CosXmlDownloadTaskResult extends CosXmlResult {
  public eTag?: string;
}