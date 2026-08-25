import { LinkedList, taskpool } from '@kit.ArkTS'
import { QCloudUserCancelError } from '../../error/QCloudUserCancelError';
import { QCloudLogger } from '../../logger/QCloudLogger';
import { QCloudEventType, QCloudPriority, QCloudTask, QCloudTaskState } from '../base/QCloudTask'
import { QCloudTransferData } from '../base/QCloudTransferData';
import { QCloudHTTPTask } from '../http/QCloudHTTPTask';
import { QCloudTaskManager } from '../QCloudTaskManager';


export  class QCloudQueue {

  queueTag:string = 'queue';
  public maxConcurrentCount = 8;
  public customConcurrentCount = 4;

  private runingTaskQueue:LinkedList<QCloudTask>;

  private heighWaitTaskQueue:LinkedList<QCloudTask>;
  private normalWaitTaskQueue:LinkedList<QCloudTask>;
  private lowWaitTaskQueue:LinkedList<QCloudTask>;

  constructor(tag?:string) {
    if (tag) {
      this.queueTag = tag;
    }
    this.runingTaskQueue = new LinkedList();
    this.heighWaitTaskQueue = new LinkedList();
    this.normalWaitTaskQueue = new LinkedList();
    this.lowWaitTaskQueue = new LinkedList();
  }

  private _logState(){
    QCloudLogger.log(`${this.queueTag}_state:runningCount:${this.runingTaskQueue.length},heighWaitCount:${this.heighWaitTaskQueue.length},normalWaitCount:${this.normalWaitTaskQueue.length},lowWaitCount:${this.lowWaitTaskQueue.length},customConcurrentCount:${this.customConcurrentCount}`,'cos_sdk_task_manager_log');
  }

  public addTask(task:QCloudTask){
    task.state = QCloudTaskState.Waiting;
    if (task.priority == QCloudPriority.High) {
      this.heighWaitTaskQueue?.add(task);
    }
    if (task.priority == QCloudPriority.Normal) {
      this.normalWaitTaskQueue?.add(task);
    }
    if (task.priority == QCloudPriority.Low) {
      this.lowWaitTaskQueue?.add(task);
    }
    QCloudLogger.log(`addTask:${task.taskId}`,'cos_sdk_task_manager_log');
    this._logState();
    this.startTask();
    task.runOnQueue = this;
  }

  public cancelTask(taskId:number):boolean{
    let RemoveTask = (list: LinkedList<QCloudTask>): boolean => {
      for (let i = 0; i < list.length; i++) {
        let task = list.get(i);
        if (task.taskId == taskId) {
          task.state = QCloudTaskState.Cancel;
          list.remove(task);
          return true;
        }
      }
      return false;
    }
    let result :boolean = RemoveTask(this.heighWaitTaskQueue);
    if (!result) {
      result = RemoveTask(this.normalWaitTaskQueue);
    }
    if (!result) {
      result = RemoveTask(this.lowWaitTaskQueue);
    }
    if (!result) {
      this.cancelRunningTask(taskId);
    }
    if (result) {
      QCloudLogger.log(`cancelTask:${taskId}`,'cos_sdk_task_manager_log');
    }
    this._logState();
    this.startTask();
    return result;
  }

  private cancelRunningTask(taskId:number){
    for (let i = 0; i < this.runingTaskQueue.length; i++) {
      let task = this.runingTaskQueue.get(i);
      if (task.taskId == taskId) {
        task.cancel();
        task.state = QCloudTaskState.Cancel;
        return;
      }
    }
  }

  public cancelAll(){
    this.heighWaitTaskQueue.forEach((value)=>{value.state = QCloudTaskState.Cancel})
    this.normalWaitTaskQueue.forEach((value)=>{value.state = QCloudTaskState.Cancel})
    this.lowWaitTaskQueue.forEach((value)=>{value.state = QCloudTaskState.Cancel})

    this.heighWaitTaskQueue.clear();
    this.normalWaitTaskQueue.clear();
    this.lowWaitTaskQueue.clear();

    for (const task of this.runingTaskQueue) {
      task.cancel();
    }
    QCloudLogger.log(`cancelAll`,'cos_sdk_task_manager_log');
    this._logState();
  }

  private async startTask(){
    if (this.heighWaitTaskQueue.length == 0 && this.lowWaitTaskQueue.length == 0 && this.normalWaitTaskQueue.length == 0){
      return;
    }
    if (this.customConcurrentCount > 0 && this.runingTaskQueue.length >= this.customConcurrentCount) {
      return;
    }
    let RuningTask = async (queue: LinkedList<QCloudTask>): Promise<void> =>  {
      let task = queue.getFirst();
      this.runingTaskQueue.add(task);
      queue.remove(task);
      try {
        await task.executeTask();
      } catch (e) {
        // 执行任务之前，构建异常，直接结束
        task.state = QCloudTaskState.Finish;
        task.onTaskReceiveData(new QCloudTransferData(QCloudEventType.taskError,null,e))
        this.runingTaskQueue.remove(task);
        return;
      }
      try {
        // 若在构建请求期间已被取消，则不再发起网络请求，直接结束
        if (task.state === QCloudTaskState.Cancel) {
          task.onTaskReceiveData(new QCloudTransferData(QCloudEventType.cancel,null,null))
          this.runingTaskQueue.remove(task);
          this.startTask();
          return;
        }
        // 先迁移到 Process 再发起网络，避免自定义网络层同步回调时状态被覆盖
        task.state = QCloudTaskState.Process;
        QCloudLogger.log(`startTask:${task.taskId}`,'cos_sdk_task_manager_log');
        this._logState();
        task.startNetworkExecute()
      } catch (e) {
        this.taskReceiveData(task.taskId,new QCloudTransferData(QCloudEventType.taskError,null,e));
      }
    }

    if (this.heighWaitTaskQueue.length>0) {
      RuningTask(this.heighWaitTaskQueue);
    }else if (this.normalWaitTaskQueue.length>0) {
      RuningTask(this.normalWaitTaskQueue);
    }else if (this.lowWaitTaskQueue.length>0) {
      RuningTask(this.lowWaitTaskQueue);
    }
  }

  private markHostSwitched(task: QCloudTask): boolean {
    // 如果已经切换过域名，不再切换
    if (task.retry.isHostSwitched()) {
      return false;
    }

    // 只有 QCloudHTTPTask 才支持域名切换
    if (!(task instanceof QCloudHTTPTask)) {
      return false;
    }

    const httpTask = task as QCloudHTTPTask<Object>;

    // 检查是否禁用了备用域名
    if (httpTask.httpRequest.disableBackupHost) {
      return false;
    }

    // 使用 HttpRequest 的 needChangeHost 方法检查域名是否支持切换
    let canSwitch = httpTask.httpRequest.needChangeHost(httpTask.httpRequest.host);
    if (canSwitch) {
      task.retry.markHostSwitched();
    }
    return canSwitch;
  }

  private needRetry(data: QCloudTransferData, task: QCloudTask): boolean {
    if (data.error || data.eventType === QCloudEventType.netError){
      if (task.retry.shouldRetry()) {
        if(task.retry.isLastRetry()){
          this.markHostSwitched(task);
        }
        return true;
      } else {
        return false;
      }
    }
    // 处理 HTTP 响应状态码
    if (data.eventType === QCloudEventType.finish) {
      const statusCode = data.result as number;

      // 2XX：成功，不重试不切换
      if (statusCode >= 200 && statusCode < 300) {
        return false;
      }

      // 3XX：不重试，满足条件时切换域名
      if (statusCode >= 300 && statusCode < 400) {
        if (task.retry.shouldRetry()) {
          // 标记最大重试次数，避免再次重试
          task.retry.markMaxCount();
          const httpTask = task as QCloudHTTPTask<Object>;
          if (httpTask.httpResponse && httpTask.httpResponse.headers &&
            httpTask.httpResponse.headers["x-cos-request-id"] === undefined) {
            return this.markHostSwitched(task);
          }
          return false;
        } else {
          return false;
        }
      }

      // 4XX：客户端错误，不重试不切换
      if (statusCode >= 400 && statusCode < 500) {
        return false;
      }

      // 5XX：服务端错误，先重试，最后一次尝试切换域名
      if (statusCode >= 500) {
        if (task.retry.shouldRetry()) {
          if(task.retry.isLastRetry()){
            const httpTask = task as QCloudHTTPTask<Object>;
            if (httpTask.httpResponse && httpTask.httpResponse.headers &&
              httpTask.httpResponse.headers["x-cos-request-id"] === undefined) {
              this.markHostSwitched(task);
            }
          }
          return true;
        } else {
          return false;
        }
      }
    }
    return false;
  }

  public taskReceiveData(taskId: number, data: QCloudTransferData) {
    let task = this.getRunningTask(taskId);
    if (!task) {
      return;
    }

    if (this.needRetry(data,task)){
      setTimeout(() => {
        task?.retry.retry();
        if (task) {
          this.runingTaskQueue.remove(task);
          task.reset();
          this.heighWaitTaskQueue.add(task);
          QCloudLogger.log(`retryTask:${task.taskId}`, 'cos_sdk_task_manager_log');
          this._logState();
          this.startTask();
        }
      }, task.retry.sleep);
    } else {
      if (data.eventType == QCloudEventType.finish || data.eventType == QCloudEventType.taskError ||
          data.eventType == QCloudEventType.cancel || data.eventType == QCloudEventType.netError) {
        if (data.eventType == QCloudEventType.cancel) {
          task.state = QCloudTaskState.Cancel;
        }
        if (data.eventType == QCloudEventType.finish || data.eventType == QCloudEventType.taskError ||
            data.eventType == QCloudEventType.netError) {
          task.state = QCloudTaskState.Finish;
        }
        QCloudLogger.log(`removeTask:${task.taskId}`, 'cos_sdk_task_manager_log');
        task.onTaskReceiveData(data);
        this.runingTaskQueue.remove(task);
        this.startTask();
      } else {
        task.onTaskReceiveData(data);
      }
    }
  }

  public getRunningTask(taskId:number) : QCloudTask|null{
    for (const task of this.runingTaskQueue) {
      if (taskId == task.taskId) {
        return task;
      }
    }
    return null;
  }
}