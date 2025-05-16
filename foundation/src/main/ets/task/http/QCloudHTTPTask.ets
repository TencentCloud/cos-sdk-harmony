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

export class QCloudHTTPTask<T> extends QCloudTask {
  private readonly TAG = "HTTP";
  httpRequest:QCloudHttpRequest<T>;

  requestData:QCloudRequestData;
  private httpResponse: HttpResponse<T>|undefined;

  onHeaderReceive: Callback<Record<string, string>> | undefined;
  onProgress: Callback<HttpProgress> | undefined;
  onSuccess: Callback<HttpResponse<T>> | undefined;
  onFailure: Callback<Error> | undefined;

  constructor(httpRequest:QCloudHttpRequest<T>) {
    super(TaskHTTPExecuteFunc);
    this.httpRequest = httpRequest;
    this.requestData = new QCloudRequestData();
  }

  async buildRequestData():Promise<boolean>{
    await this.httpRequest.prepareRequestData();
    if (this.retry.currentCount() > 0) {
      this.httpRequest.addHeader("x-cos-sdk-retry","true");
    }
    let url = this.httpRequest?.buildURL();

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
    return true;
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
    let event: emitter.InnerEvent = {
      eventId: this.taskId + QCloudTask.K_CANCEL_EVENT_BASE,
      priority: emitter.EventPriority.HIGH
    };
    emitter.emit(event);
  }


  shouldRetry(error:Error):boolean{
    if (!super.shouldRetry(error)) {
      return false;
    }
    return this.httpRequest.shouldRetry(error);
  }

  public reset(): void {
    super.reset();
    this.httpRequest.reset();
  }
}