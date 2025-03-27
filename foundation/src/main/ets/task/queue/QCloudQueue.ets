import { LinkedList, taskpool } from '@kit.ArkTS'
import { QCloudUserCancelError } from '../../error/QCloudUserCancelError';
import { QCloudLogger } from '../../logger/QCloudLogger';
import { QCloudEventType, QCloudPriority, QCloudTask, QCloudTaskState } from '../base/QCloudTask'
import { QCloudTransferData } from '../base/QCloudTransferData';
import { TaskHTTPExecuteFunc } from '../http/TaskHTTPExecuteFunc';
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
        let hTask = new taskpool.Task(TaskHTTPExecuteFunc,task.getRequestData());
        if (task.state === QCloudTaskState.Cancel) {
          task.onTaskReceiveData(new QCloudTransferData(QCloudEventType.cancel,null,null))
          this.runingTaskQueue.remove(task);
        }else{
          taskpool.execute(hTask);
          QCloudLogger.log(`startTask:${task.taskId}`,'cos_sdk_task_manager_log');
          this._logState();
          task.state = QCloudTaskState.Process;
        }
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

  public taskReceiveData(taskId:number,data:QCloudTransferData){
    let task = this.getRunningTask(taskId);
    if (!task) {
      return;
    }

    if ((data.error && task.shouldRetry(data.error)) ||
      ((data.eventType === QCloudEventType.netError || (data.eventType === QCloudEventType.finish && (data.result as number) >= 500)) && task.retry.shouldRetry())){
      setTimeout(()=>{
        if (task) {
          this.runingTaskQueue.remove(task);
          task.reset();
          this.heighWaitTaskQueue.add(task);
          QCloudLogger.log(`retryTask:${task.taskId}`,'cos_sdk_task_manager_log');
          this._logState();
          this.startTask()
        }
      },task.retry.sleep);
    }else{
      if (data.eventType == QCloudEventType.finish || data.eventType == QCloudEventType.taskError || data.eventType == QCloudEventType.cancel) {
        if (data.eventType == QCloudEventType.cancel) {
          task.state = QCloudTaskState.Cancel;
        }
        if (data.eventType == QCloudEventType.finish || data.eventType == QCloudEventType.taskError) {
          task.state = QCloudTaskState.Finish;
        }
        QCloudLogger.log(`removeTask:${task.taskId}`,'cos_sdk_task_manager_log');
        task.onTaskReceiveData(data);
        this.runingTaskQueue.remove(task);
        this.startTask();
      }else{
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