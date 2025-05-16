import { QCloudEventType, QCloudTask } from '../base/QCloudTask';
import { QCloudTransferData } from '../base/QCloudTransferData';
import emitter from '@ohos.events.emitter';
import http from '@ohos.net.http';
import { QCloudRequestData } from './QCloudRequestData';
import { HttpProgress, ProgressController } from '../../net/HttpProgress';
import { HashMap } from '@kit.ArkTS';
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class QCloudSessionManager {
  private static service: QCloudSessionManager;

  public session :rcp.Session = rcp.createSession();

  public static manager(): QCloudSessionManager {
    if (!QCloudSessionManager.service) {
      QCloudSessionManager.service = new QCloudSessionManager();
    }
    return QCloudSessionManager.service;
  }
}

export async function TaskHTTPExecuteFunc(qcloudRequestData: QCloudRequestData) {

  let resultMap = new HashMap<number, object>();
  let sendSet = new Set<number>();

  let event: emitter.InnerEvent = {
    eventId: qcloudRequestData.taskId,
    priority: emitter.EventPriority.HIGH
  };

  let SendEvent = (data: QCloudTransferData) => {
    let eventData: emitter.EventData = {
      data: {
        "taskId": qcloudRequestData.taskId,
        "data": data,
      }
    };
    emitter.emit(event, eventData);
  }

  let SendOrderEvent = (data: QCloudTransferData, order: number, totalCount: number) => {
    resultMap.set(order, data);
    for (let index = 0; index <= totalCount; index++) {
      if (sendSet.has(index)) {
        continue;
      }

      let sendData = resultMap.get(index);
      if (!sendData) {
        break;
      }
      let eventData: emitter.EventData = {
        data: {
          "taskId": qcloudRequestData.taskId,
          "data": sendData,
        }
      };
      emitter.emit(event, eventData);
      sendSet.add(index);
    }
  }

  const progressController = new ProgressController((progress: HttpProgress) => {
    SendEvent(new QCloudTransferData(QCloudEventType.dataProgress, progress, null));
  }, qcloudRequestData.progressGranularity);
  const customHttpEventsHandler: rcp.HttpEventsHandler = {
    onDataReceive: (incomingData: ArrayBuffer) => {
      SendEvent(new QCloudTransferData(QCloudEventType.dataReceive, incomingData, null));
    },
    onUploadProgress: (totalSize: number, transferredSize: number) => {
      if (qcloudRequestData.method == http.RequestMethod.PUT) {
        progressController.updateProgress(transferredSize, totalSize);
      }
    },
    onDownloadProgress: (totalSize: number, transferredSize: number) => {
      if (qcloudRequestData.method == http.RequestMethod.GET) {
        progressController.updateProgress(transferredSize, totalSize);
      }
    },
    onHeaderReceive: (headers: rcp.ResponseHeaders) => {
      SendOrderEvent(new QCloudTransferData(QCloudEventType.headerReceive, headers, null), 0, 3);
    },
    onDataEnd: () => {
      SendOrderEvent(new QCloudTransferData(QCloudEventType.dataEnd, null, null), 1, 3);
    },
    onCanceled: () => {
    },
  };

  let requestConfig = qcloudRequestData.requestConfiguration;
  if (requestConfig?.tracing) {
    requestConfig.tracing.httpEventsHandler = customHttpEventsHandler
  } else {
    const tracingConfig: rcp.TracingConfiguration = {
      httpEventsHandler: customHttpEventsHandler
    };
    requestConfig!.tracing = tracingConfig;
  }

  let req = new rcp.Request(qcloudRequestData.url!, qcloudRequestData.method,qcloudRequestData.headers,qcloudRequestData.content,undefined,undefined,requestConfig);

  QCloudSessionManager.manager().session.fetch(req).then((response) => {
    SendOrderEvent(new QCloudTransferData(QCloudEventType.finish, response.statusCode, null), 2, 3);
    finish();
  }).catch((err: BusinessError) => {
    SendEvent(new QCloudTransferData(QCloudEventType.netError, null, err));
    finish();
  });

  let cancelEvent: emitter.InnerEvent = {
    eventId: qcloudRequestData.taskId + 1000000
  };
  emitter.on(cancelEvent, (eventData: emitter.EventData): void => {
    QCloudSessionManager.manager().session.cancel(req);
    SendEvent(new QCloudTransferData(QCloudEventType.cancel, null, null))
    finish();
  });

  let finish = () => {
    resultMap.clear();
    sendSet.clear();
  }
}