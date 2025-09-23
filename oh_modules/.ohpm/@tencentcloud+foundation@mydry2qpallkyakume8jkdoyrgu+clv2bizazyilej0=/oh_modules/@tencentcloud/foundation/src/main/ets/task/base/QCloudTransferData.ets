import { QCloudEventType } from './QCloudTask';
import { rcp } from '@kit.RemoteCommunicationKit';

export class QCloudTransferData {
  eventType?:QCloudEventType;
  error: Error|null;
  result:object|number|null;
  timeInfo?: rcp.TimeInfo;
  constructor(eventType:QCloudEventType,result:object|number|null,error:Error|null,timeInfo?: rcp.TimeInfo) {
    this.eventType = eventType;
    this.error = error;
    this.result = result;
    this.timeInfo = timeInfo;
  }
}

