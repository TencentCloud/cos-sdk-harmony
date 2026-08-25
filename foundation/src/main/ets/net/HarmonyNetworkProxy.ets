import http from '@ohos.net.http';
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { NetworkProxy } from './NetworkProxy';
import { CustomNetworkRequest } from './CustomNetworkRequest';
import { CustomNetworkResponseHandler } from './CustomNetworkResponseHandler';
import { QCloudResponseHandler } from './QCloudResponseHandler';
import { QCloudSessionManager } from '../task/http/TaskHTTPExecuteFunc';

/**
 * 默认网络执行代理：基于 HarmonyOS RemoteCommunicationKit（rcp）实现。
 *
 * 逻辑与原 TaskHTTPExecuteFunc 等价，区别仅在于把 rcp 的回调统一映射到
 * {@link CustomNetworkResponseHandler}，从而与自定义网络实现共用同一套事件回发机制。
 * 客户不设置自定义 networkClient 时，SDK 走本实现，行为与旧版本保持一致。
 */
export class HarmonyNetworkProxy extends NetworkProxy {
  private request?: rcp.Request;

  executeHttpRequest(request: CustomNetworkRequest, handler: CustomNetworkResponseHandler): void {
    // 原生高级配置（透传自 CosXmlServiceConfig 的 requestConfiguration/dnsConfiguration，
    // 经 buildRequestConfiguration 构建为 rcp.Configuration）
    let requestConfig: rcp.Configuration = request.nativeRequestConfiguration as rcp.Configuration;
    if (!requestConfig) {
      requestConfig = {};
    }

    const customHttpEventsHandler: rcp.HttpEventsHandler = {
      onDataReceive: (incomingData: ArrayBuffer) => {
        handler.onData(incomingData);
      },
      onUploadProgress: (totalSize: number, transferredSize: number) => {
        if (request.method == http.RequestMethod.PUT) {
          handler.onProgress(transferredSize, totalSize);
        }
      },
      onDownloadProgress: (totalSize: number, transferredSize: number) => {
        if (request.method == http.RequestMethod.GET) {
          handler.onProgress(transferredSize, totalSize);
        }
      },
      onHeaderReceive: (headers: rcp.ResponseHeaders) => {
        handler.onResponseHeaders(headers as Record<string, string>);
      },
      onDataEnd: () => {
        // dataEnd 与 finish 合并在 onComplete 中有序回发
      },
      onCanceled: () => {
      },
    };

    if (requestConfig.tracing) {
      requestConfig.tracing.httpEventsHandler = customHttpEventsHandler;
      requestConfig.tracing.collectTimeInfo = true;
    } else {
      const tracingConfig: rcp.TracingConfiguration = {
        collectTimeInfo: true,
        httpEventsHandler: customHttpEventsHandler
      };
      requestConfig.tracing = tracingConfig;
    }

    this.request = new rcp.Request(request.url, request.method, request.headers, request.body,
      undefined, undefined, requestConfig);

    QCloudSessionManager.manager().session.fetch(this.request).then((response: rcp.Response) => {
      if (handler instanceof QCloudResponseHandler && response.timeInfo) {
        handler.setTimeInfo(response.timeInfo);
      }
      handler.onComplete(response.statusCode);
    }).catch((err: BusinessError) => {
      handler.onFailure(err);
    });
  }

  cancel(): void {
    if (this.request) {
      QCloudSessionManager.manager().session.cancel(this.request);
    }
  }
}
