import { QCloudEventType } from './QCloudTask';

export class QCloudTransferData {
  eventType?:QCloudEventType;
  error: Error|null;
  result:object|number|null;
  constructor(eventType:QCloudEventType,result:object|number|null,error:Error|null) {
    this.eventType = eventType;
    this.error = error;
    this.result = result;
  }
}

