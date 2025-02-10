import { taskpool } from '@kit.ArkTS';
import { QCloudLogger } from '../../logger/QCloudLogger';
import { QCloudQueue } from '../queue/QCloudQueue';

import { QCloudTransferData } from './QCloudTransferData';
import emitter from '@ohos.events.emitter';
import { QCloudRequestData } from '../http/QCloudRequestData';
import { RetryHandler } from '../../retry/RetryHandler';

export enum QCloudEventType {
  netError = 'netError',
  taskError = 'taskError',
  cancel = 'cancel',
  finish = 'finish',
  headerReceive = 'headerReceive',
  dataProgress = 'dataProgress',
  dataReceive = 'dataReceive', //
  dataEnd = 'dataEnd' // 结束
}
export enum QCloudPriority {High = 0, Normal = 1, Low = 2 }
export enum QCloudTaskState {Init = 0,Waiting = 1, Process = 2, Cancel = 3,Finish = 4}

export class QCloudTask {

  private static K_TASK_ID = 33333;
  public static K_CANCEL_EVENT_BASE = 1000000;
  mainFunc:Function;
  runOnQueue?:QCloudQueue;
  priority:QCloudPriority;
  state = QCloudTaskState.Init;
  taskId:number;
  hTask?:taskpool.Task;
  retry = new RetryHandler(3,1);

  constructor(mainFunc:Function) {
    this.mainFunc = mainFunc;
    this.taskId = QCloudTask.K_TASK_ID ++;
    this.priority = QCloudPriority.Normal;
    this.state = QCloudTaskState.Init;

    let event: emitter.InnerEvent = {
      eventId: this.taskId
    };
    emitter.on(event, (eventData: emitter.EventData): void => {
      let data = eventData.data;
      this.runOnQueue?.taskReceiveData(this.taskId,data!["data"] as QCloudTransferData)
    });
  }

  getRequestData():object{
    return new QCloudRequestData();
  }

  /*构建请求数据*/
  async buildRequestData(){
    return true;
  }
  /**/
  async executeTask(){
    await this.buildRequestData();
  }

  shouldRetry(error:Error):boolean{
    if (!this.retry.shouldRetry()) {
      return false;
    }
    return true;
  }

  cancel(){
    // 任务未开始，只需在manager等待队列中删除即可。
    if (this.state != QCloudTaskState.Process) {
      return;
    }
  }

  reset(){
    this.state = QCloudTaskState.Waiting;
  }

  public onTaskReceiveData(data:QCloudTransferData){
    QCloudLogger.info(`QCloudCOSFoundation:task_onTaskReceiveData:${this.taskId}_${data}`);
  }
}