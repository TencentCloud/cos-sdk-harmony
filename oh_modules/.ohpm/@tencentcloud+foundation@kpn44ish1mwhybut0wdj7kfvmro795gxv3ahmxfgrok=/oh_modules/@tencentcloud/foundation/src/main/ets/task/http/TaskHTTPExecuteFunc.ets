import { QCloudEventType, QCloudTask } from '../base/QCloudTask';
import { QCloudTransferData } from '../base/QCloudTransferData';
import emitter from '@ohos.events.emitter';
import http from '@ohos.net.http';
import { QCloudRequestData } from './QCloudRequestData';
import { HttpProgress } from '../../net/HttpProgress';
import { QCloudLogger } from '../../logger/QCloudLogger';
import { HashMap } from '@kit.ArkTS';
enum SendEventOrder {}
@Concurrent
export function TaskHTTPExecuteFunc(qcloudRequestData:QCloudRequestData){

  let resultMap = new HashMap<number,object>();
  let sendSet = new Set<number>();

  let event: emitter.InnerEvent = {
    eventId: qcloudRequestData.taskId,
    priority: emitter.EventPriority.HIGH
  };

  let httpRequest = http.createHttp();
  let cancelEvent: emitter.InnerEvent = {
    eventId: qcloudRequestData.taskId + 1000000
  };
  emitter.once(cancelEvent, (eventData: emitter.EventData): void => {
    SendEvent(new QCloudTransferData(QCloudEventType.cancel, null,null))
    dealloc();
  });

  let SendEvent = (data: QCloudTransferData) =>  {
    let eventData: emitter.EventData = {
      data: {
        "taskId": qcloudRequestData.taskId,
        "data": data,
      }
    };
    emitter.emit(event,eventData);
  }

  let SendOrderEvent = (data: QCloudTransferData,order:number,totalCount:number) =>  {
    resultMap.set(order,data);
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
      emitter.emit(event,eventData);
      sendSet.add(index);
    }
    if (sendSet.size == totalCount) {
      dealloc();
    }
  }

  httpRequest.on("dataReceiveProgress", (data: http.DataReceiveProgressInfo) => {
    if (qcloudRequestData.httpRequestOptions?.method == http.RequestMethod.GET) {
      SendEvent(new QCloudTransferData(QCloudEventType.dataProgress, new HttpProgress(data.receiveSize, data.totalSize), null));
    }
  });

  httpRequest.on("dataSendProgress", (data: http.DataSendProgressInfo) => {
    if (qcloudRequestData.httpRequestOptions?.method == http.RequestMethod.PUT) {
      SendEvent(new QCloudTransferData(QCloudEventType.dataProgress, new HttpProgress(data.sendSize, data.totalSize), null));
    }
  });

  httpRequest.on("dataReceive", (data: ArrayBuffer) => {
    SendEvent(new QCloudTransferData(QCloudEventType.dataReceive, data, null));
  });


  httpRequest.on("headersReceive", (header: object) => {
    SendOrderEvent(new QCloudTransferData(QCloudEventType.headerReceive, header, null),0,3);
  });


  httpRequest.on("dataEnd", () => {
    SendOrderEvent(new QCloudTransferData(QCloudEventType.dataEnd, null, null),2,3);
  });


  let promise = httpRequest.requestInStream(qcloudRequestData.url, qcloudRequestData.httpRequestOptions);
  promise.then((httpCode: number) => {
    SendOrderEvent(new QCloudTransferData(QCloudEventType.finish, httpCode, null),1,3);
  }).catch((err: Error) => {
    SendEvent(new QCloudTransferData(QCloudEventType.netError, null, err));
  });

  let dealloc = () => {
    httpRequest.off("dataReceive");
    httpRequest.off("dataReceiveProgress");
    httpRequest.off("dataSendProgress");
    httpRequest.off("dataEnd");
    httpRequest.off("headersReceive");
    httpRequest.destroy();
    resultMap.clear();
    sendSet.clear();
  }
}