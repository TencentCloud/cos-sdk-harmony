import { QCloudEventType, QCloudTask } from '../base/QCloudTask';
import { QCloudTransferData } from '../base/QCloudTransferData';
import { QCloudRequestData } from './QCloudRequestData';
import { HttpRequest } from '../../net/HttpRequest';
import { QCloudSignatureBuilder } from '../../authentation/QCloudSignatureBuilder';
import emitter from '@ohos.events.emitter';
import { Callback } from '@ohos.base';
import { HttpProgress } from '../../net/HttpProgress';
import { HttpResponse } from '../../net/HttpResponse';
import { TaskHTTPExecuteFunc } from './TaskHTTPExecuteFunc';
import { QCloudUserCancelError } from '../../error/QCloudUserCancelError';
import { QCloudNetError } from '../../error/QCloudNetError';
import { QCloudTaskError } from '../../error/QCloudTaskError';
import { QCloudHttpRequest } from '../../net/QCloudHttpRequest';
import { QCloudAuthenticationError } from '../../error/QCloudAuthenticationError';
import { QCloudLogger } from '../../logger/QCloudLogger';
import { HttpHeader } from '../../net/HttpConstants';
import { rcp } from '@kit.RemoteCommunicationKit';
import { NetworkClient } from '../../net/NetworkClient';
import { NetworkProxy } from '../../net/NetworkProxy';
import { HarmonyNetworkClient } from '../../net/HarmonyNetworkClient';
import { QCloudResponseHandler } from '../../net/QCloudResponseHandler';
import { CustomNetworkRequest } from '../../net/CustomNetworkRequest';

export class QCloudHTTPTask<T> extends QCloudTask {
  private readonly TAG = "HTTP";
  httpRequest:QCloudHttpRequest<T>;

  requestData:QCloudRequestData;
  /** 交给网络层执行的解耦请求数据（由 buildRequestData 构建） */
  customRequest:CustomNetworkRequest;
  /** 网络客户端（配置+工厂），默认使用 rcp 实现，可由 CosXmlBaseService 注入自定义实现 */
  networkClient:NetworkClient = new HarmonyNetworkClient();
  /** 当次请求的网络执行代理（含重试的每一次执行都会重新获取） */
  private networkProxy?:NetworkProxy;
  /** 当次请求的响应回调处理器 */
  private responseHandler?:QCloudResponseHandler;
  httpResponse: HttpResponse<T>|undefined;

  onHeaderReceive: Callback<Record<string, string>> | undefined;
  onProgress: Callback<HttpProgress> | undefined;
  onSuccess: Callback<HttpResponse<T>> | undefined;
  onFailure: Callback<Error> | undefined;
  onTimeInfo: Callback<rcp.TimeInfo> | undefined;

  constructor(httpRequest:QCloudHttpRequest<T>) {
    super(TaskHTTPExecuteFunc);
    this.httpRequest = httpRequest;
    this.requestData = new QCloudRequestData();
    this.customRequest = new CustomNetworkRequest();
  }

  async buildRequestData():Promise<boolean>{
    await this.httpRequest.prepareRequestData();
    // 根据域名切换标记决定是否使用备用域名
    let change = this.retry.isHostSwitched();
    // 重试时添加重试标记头（重试次数 > 0 表示正在重试）
    if (this.retry.currentCount() > 0) {
      this.httpRequest.addHeader("x-cos-sdk-retry","true");
    }
    let url = this.httpRequest?.buildURL(change);

    // 请求如果已经签名则不再本地或者服务端签名
    if(!this.httpRequest.headers.has(HttpHeader.AUTHORIZATION) || this.httpRequest.headers.get(HttpHeader.AUTHORIZATION)!.length == 0){
      // 客户端签名
      let signature = await QCloudSignatureBuilder.signatureBuild(this.httpRequest);
      if (signature){
        if (!this.httpRequest.isSignedInURL) {
          this.httpRequest.addHeader(HttpHeader.AUTHORIZATION,signature.authorization!);
        }else{
          if (url.includes("?")) {
            url += `&${signature.authorization}`;
          }else{
            url += `?${signature.authorization}`;
          }
          if (signature.token && signature.token.length > 0) {
            url += `&${signature.tokenName}=${signature.token}`;
          }
        }
      }

      // 服务端签名
      if(this.httpRequest.selfSignCallBack){
        this.httpRequest.selfSignCallBack(this.httpRequest);
      }
    }
    this.requestData.url = url;
    this.requestData.headers = this.httpRequest.buildHeader();
    this.requestData.content = this.httpRequest.buildBody();
    this.requestData.method = this.httpRequest.method;
    this.requestData.requestConfiguration = this.httpRequest.buildRequestConfiguration();
    this.requestData.progressGranularity = this.httpRequest.progressGranularity;
    this.requestData.taskId = this.taskId;

    // 构建交给网络层的解耦请求数据（不含 rcp 类型；rcp 高级配置经 nativeRequestConfiguration 透传给默认实现）
    this.customRequest.taskId = this.taskId;
    this.customRequest.method = this.httpRequest.method as string;
    this.customRequest.url = url;
    this.customRequest.headers = this.requestData.headers as Record<string, string>;
    this.customRequest.body = this.requestData.content as ArrayBuffer | string;
    this.customRequest.connectTimeoutMs = this.httpRequest.connectTimeout;
    this.customRequest.readTimeoutMs = this.httpRequest.readTimeout;
    this.customRequest.nativeRequestConfiguration = this.requestData.requestConfiguration;
    return true;
  }

  /**
   * 通过网络层执行请求：获取网络代理与响应处理器，发起请求。
   * 由队列在 buildRequestData 完成后调用。含重试的每一次执行都会重新获取网络代理。
   */
  public startNetworkExecute(): void {
    this.responseHandler = new QCloudResponseHandler(this.taskId, this.requestData.progressGranularity);
    this.networkProxy = this.networkClient.getNetworkProxy();
    this.networkProxy.executeHttpRequest(this.customRequest, this.responseHandler);
  }

  public onTaskReceiveData(data: QCloudTransferData): void {
    if (data.eventType == QCloudEventType.netError) {
      if(data.error){
        QCloudLogger.info(new QCloudNetError(data.error), this.TAG+"_err");
      }
      if (this.onFailure) {
        this.onFailure(new QCloudNetError(data.error) as Error);
        return;
      }
    }

    if (data.eventType == QCloudEventType.taskError) {
      emitter.off(this.taskId);
      if (this.onFailure) {
        if(data.error instanceof QCloudAuthenticationError){
          // task执行过程中可能会抛QCloudAuthenticationError，需要单独抛出
          this.onFailure(data.error as Error);
        } else {
          this.onFailure(new QCloudTaskError(data.error) as Error);
        }
        return;
      }
    }

    if (data.eventType == QCloudEventType.cancel) {
      emitter.off(this.taskId);
      if (this.onFailure) {
        this.onFailure(new QCloudUserCancelError() as Error);
        return;
      }
    }

    if (data.eventType == QCloudEventType.finish) {
      try {
        emitter.off(this.taskId);
        QCloudLogger.info((data.result as number).toString(), this.TAG+"_httpCode");
        if(this.onTimeInfo && data.timeInfo){
          this.onTimeInfo(data.timeInfo)
        }
        let t = this.httpRequest.responseBodyConverter.convertEnd(data.result as number);
        if (this.onSuccess) {
          if(this.httpResponse){
            this.httpResponse.httpCode = data.result as number;
            this.httpResponse.content = t;
          }
        }
      } catch (err) {
        if (this.onFailure) {
          this.onFailure(err);
          return;
        }
      }
      if (this.onSuccess && this.httpResponse) {
        this.onSuccess(this.httpResponse);
        return;
      }
    }

    if (data.eventType == QCloudEventType.headerReceive) {
      if(data.result){
        QCloudLogger.info(data.result as Record<string, string>, this.TAG+"_headersReceive");
      }
      try {
        this.httpResponse = new HttpResponse()
        if(this.httpResponse){
          this.httpResponse.headers = data.result as Record<string, string>;
        }
        this.httpRequest.responseBodyConverter.headersReceive(data.result as Record<string, string>)
      } catch (err) {
        if (this.onFailure) {
          this.onFailure(err);
          return;
        }
      }
      if (this.onHeaderReceive) {
        this.onHeaderReceive(data.result as Record<string, string>);
      }
    }

    if (data.eventType == QCloudEventType.dataReceive) {
      try {
        this.httpRequest.responseBodyConverter.convertPart(data.result as ArrayBuffer)
      } catch (err) {
        if (this.onFailure) {
          this.onFailure(err);
          return;
        }
      }
    }

    if (data.eventType == QCloudEventType.dataEnd) {
      QCloudLogger.info("dataEnd !", this.TAG+"_dataEnd");
    }

    if (data.eventType == QCloudEventType.dataProgress) {
      if (this.onProgress) {
        let httpProgress: HttpProgress = data.result as HttpProgress;
        this.onProgress(httpProgress);
      }
    }
  }

  public getRequestData():QCloudRequestData {
    if(this.requestData) {
      QCloudLogger.info(this.requestData.url!, this.TAG + "_url");
      QCloudLogger.info(this.requestData.requestConfiguration!, this.TAG + "_request");
    }
    return this.requestData;
  }

  public cancel(){
    super.cancel();
    // 先让 SDK 进入取消终态：保证底层 cancel 触发的失败回调（部分网络库 cancel 会同步/异步回调 onFailure）
    // 被响应处理器忽略，避免用户主动取消被当成网络错误而触发重试。
    this.responseHandler?.emitCancel();
    try {
      this.networkProxy?.cancel();
    } catch (e) {
      // 已进入取消终态，忽略底层 cancel 抛出的异常
    }
  }

  public reset(): void {
    super.reset();
    this.httpRequest.reset();
  }

  /**
   * 获取当前重试次数
   */
  public getRetryCount(): number {
    return this.retry.currentCount();
  }

  /**
   * 获取最终请求的 URL
   */
  public getRequestUrl(): string | undefined {
    return this.requestData?.url?.toString();
  }
}