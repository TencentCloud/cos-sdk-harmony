import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';
import {
  CosXmlBaseService,
  CosXmlServiceConfig,
  NetworkClient,
  NetworkProxy,
  CustomNetworkRequest,
  CustomNetworkResponseHandler,
  CredentialCallBack
} from '@tencentcloud/cos';

/**
 * 自定义网络层用法示例。
 *
 * 通过继承 NetworkClient / NetworkProxy，使用 @ohos.net.http 接管 COS SDK 的网络通信。
 * 你也可以替换为任意自研网络库、支持 DNS 优化 / QUIC / 弱网优化等。
 *
 * 未配置 networkClient 时，SDK 使用默认的 rcp 网络实现，行为与旧版本一致。
 */

/**
 * 第一步：实现网络执行代理（承载单次请求的执行与取消）。
 * 使用 requestInStream 流式接收响应，支持大文件分片下载与取消。
 *
 * 注意：requestInStream 的回调只提供 HTTP 状态码，响应体是否接收完毕由独立的 dataEnd 事件表示。
 * 因此必须等「状态码」和「dataEnd」都到达后再调用 onComplete，避免在流未结束时提前完成/清理。
 */
class OhHttpNetworkProxy extends NetworkProxy {
  private httpRequest?: http.HttpRequest;
  private statusCode?: number;
  private dataEnded: boolean = false;
  private terminated: boolean = false;
  private handler?: CustomNetworkResponseHandler;

  executeHttpRequest(request: CustomNetworkRequest, handler: CustomNetworkResponseHandler): void {
    this.handler = handler;
    this.httpRequest = http.createHttp();

    // 响应头
    this.httpRequest.on('headersReceive', (headers: Object) => {
      handler.onResponseHeaders(headers as Record<string, string>);
    });
    // 响应体分片（流式，支持大文件下载）
    this.httpRequest.on('dataReceive', (chunk: ArrayBuffer) => {
      handler.onData(chunk);
    });
    // 响应体接收完毕
    this.httpRequest.on('dataEnd', () => {
      this.dataEnded = true;
      this.tryComplete();
    });
    // 上传 / 下载进度
    this.httpRequest.on('dataSendProgress', (info: http.DataSendProgressInfo) => {
      handler.onProgress(info.sendSize, info.totalSize);
    });
    this.httpRequest.on('dataReceiveProgress', (info: http.DataReceiveProgressInfo) => {
      handler.onProgress(info.receiveSize, info.totalSize);
    });

    let options: http.HttpRequestOptions = {
      method: request.method as http.RequestMethod,
      header: request.headers,
      extraData: request.body,
      connectTimeout: request.connectTimeoutMs,
      readTimeout: request.readTimeoutMs
    };

    this.httpRequest.requestInStream(request.url, options,
      (err: BusinessError, statusCode: number) => {
        if (err) {
          this.fail(err);
          return;
        }
        this.statusCode = statusCode;
        this.tryComplete();
      });
  }

  cancel(): void {
    if (this.terminated) {
      return;
    }
    this.terminated = true;
    this.cleanup();
  }

  /** 状态码与 dataEnd 都到达后才算成功结束 */
  private tryComplete(): void {
    if (this.terminated || this.statusCode === undefined || !this.dataEnded) {
      return;
    }
    this.terminated = true;
    this.handler?.onComplete(this.statusCode);
    this.cleanup();
  }

  private fail(error: Error): void {
    if (this.terminated) {
      return;
    }
    this.terminated = true;
    this.handler?.onFailure(error);
    this.cleanup();
  }

  /** 释放 HttpRequest 的事件监听与底层资源，幂等 */
  private cleanup(): void {
    if (this.httpRequest) {
      this.httpRequest.off('headersReceive');
      this.httpRequest.off('dataReceive');
      this.httpRequest.off('dataEnd');
      this.httpRequest.off('dataSendProgress');
      this.httpRequest.off('dataReceiveProgress');
      this.httpRequest.destroy();
      this.httpRequest = undefined;
    }
  }
}

/**
 * 第二步：实现网络客户端（配置 + 工厂），为每次请求产出一个代理。
 */
export class OhHttpNetworkClient extends NetworkClient {
  getNetworkProxy(): NetworkProxy {
    return new OhHttpNetworkProxy();
  }
}

/**
 * 第三步：在 CosXmlServiceConfig 中注入自定义网络客户端。
 */
export function createServiceWithCustomNetwork(context: Context,
  region: string, credentialCallBack: CredentialCallBack): CosXmlBaseService {
  let config = new CosXmlServiceConfig(region);
  config.networkClient = new OhHttpNetworkClient();
  return new CosXmlBaseService(context, config, credentialCallBack);
}
