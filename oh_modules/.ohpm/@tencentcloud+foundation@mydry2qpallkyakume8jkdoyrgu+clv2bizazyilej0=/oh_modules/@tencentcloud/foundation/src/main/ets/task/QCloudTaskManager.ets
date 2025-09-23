import { CredentialCallBack, QCloudSignatureBuilder } from '../authentation/QCloudSignatureBuilder';
import { QCloudQueue } from './queue/QCloudQueue'
import { QCloudTask } from './base/QCloudTask';
import { QCloudHTTPTask } from './http/QCloudHTTPTask';

export class QCloudTaskManager{

  downloadQueue:QCloudQueue = new QCloudQueue('downloadQueue');
  uploadQueue:QCloudQueue = new QCloudQueue('uploadQueue');
  requestQueue:QCloudQueue = new QCloudQueue('requestQueue');
  private static service: QCloudTaskManager;

  public static manager(): QCloudTaskManager {
    if (!QCloudTaskManager.service) {
      QCloudTaskManager.service = new QCloudTaskManager();
    }
    return QCloudTaskManager.service;
  }

  setDownloadConcurrentCount(count:number){
    this.downloadQueue.customConcurrentCount = count;
  }

  setUploadConcurrentCount(count:number){
    this.uploadQueue.customConcurrentCount = count;
  }

  setRequestConcurrentCount(count:number){
    this.requestQueue.customConcurrentCount = count;
  }

  public addDownloadTask(task:QCloudTask){
    this.downloadQueue.addTask(task);
  }

  public addUploadTask(task:QCloudTask){
    this.uploadQueue.addTask(task);
  }

  public addRequestTask(task:QCloudTask){
    this.requestQueue.addTask(task);
  }

  public getRunningTask(taskId:number):QCloudTask|null{
    let queues: QCloudQueue[]= [this.downloadQueue,this.uploadQueue,this.requestQueue];
    for (let queue of queues) {
      let task:QCloudTask|null = queue.getRunningTask(taskId);
      if (task) {
        return task;
      }
    }
    return null;
  }

  public cancel(taskId:number){
    let queues: QCloudQueue[]= [this.downloadQueue,this.uploadQueue,this.requestQueue];
    for (let queue of queues) {
      if (queue.cancelTask(taskId)) {
        break;
      }
    }
  }

  public cancelAll(){
    let queues: QCloudQueue[]= [this.downloadQueue,this.uploadQueue,this.requestQueue];
    for (let queue of queues) {
      queue.cancelAll();
    }
  }
}