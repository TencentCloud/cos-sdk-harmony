import emitter from '@ohos.events.emitter';
import { HashMap } from '@kit.ArkTS';
import { rcp } from '@kit.RemoteCommunicationKit';
import { QCloudEventType } from '../task/base/QCloudTask';
import { QCloudTransferData } from '../task/base/QCloudTransferData';
import { HttpProgress, ProgressController } from './HttpProgress';
import { CustomNetworkResponseHandler } from './CustomNetworkResponseHandler';

/**
 * SDK 框架内部的响应回调实现。
 *
 * 封装了原 TaskHTTPExecuteFunc 中的「事件有序回发（保证 headerReceive → dataEnd → finish 顺序）
 * + 进度频控 + 取消」逻辑，并把它统一暴露为 {@link CustomNetworkResponseHandler}。
 * 无论是默认的 rcp 网络实现还是客户自定义实现，都通过本类回发事件，
 * 从而保证事件顺序、重试语义、进度回调等下游行为完全一致。
 *
 * 每次请求（含重试的每一次）创建一个新实例，内部状态互不干扰。
 */
export class QCloudResponseHandler implements CustomNetworkResponseHandler {
  private readonly taskId: number;
  private readonly event: emitter.InnerEvent;
  private readonly resultMap: HashMap<number, object> = new HashMap();
  private readonly sendSet: Set<number> = new Set();
  private readonly progressController: ProgressController;
  private timeInfo?: rcp.TimeInfo;
  /** 是否已回调过响应头，用于在缺失响应头时兜底补偿 */
  private headerReceived: boolean = false;
  /** 一旦进入终态（完成/失败/取消），后续回调将被忽略，避免重复回发。 */
  private terminated: boolean = false;

  constructor(taskId: number, progressGranularity?: number) {
    this.taskId = taskId;
    this.event = {
      eventId: taskId,
      priority: emitter.EventPriority.HIGH
    };
    this.progressController = new ProgressController((progress: HttpProgress) => {
      this.sendEvent(new QCloudTransferData(QCloudEventType.dataProgress, progress, null));
    }, progressGranularity);
  }

  /** 立即回发一个事件。 */
  private sendEvent(data: QCloudTransferData): void {
    let eventData: emitter.EventData = {
      data: {
        "taskId": this.taskId,
        "data": data,
      }
    };
    emitter.emit(this.event, eventData);
  }

  /**
   * 有序回发事件：按 order 缓存，从 0 开始连续可达时才依次回发，
   * 保证 headerReceive(0) → dataEnd(1) → finish(2) 的顺序，即便回调到达顺序不确定。
   */
  private sendOrderEvent(data: QCloudTransferData, order: number, totalCount: number): void {
    this.resultMap.set(order, data);
    for (let index = 0; index <= totalCount; index++) {
      if (this.sendSet.has(index)) {
        continue;
      }
      let sendData = this.resultMap.get(index);
      if (!sendData) {
        break;
      }
      this.sendEvent(sendData as QCloudTransferData);
      this.sendSet.add(index);
    }
  }

  private finish(): void {
    this.resultMap.clear();
    this.sendSet.clear();
  }

  /**
   * 仅供默认 rcp 实现使用：设置本次请求的 rcp 耗时信息，随 finish 事件回传给上层 onTimeInfo。
   * 自定义实现无需调用，onTimeInfo 将不回调。
   */
  public setTimeInfo(timeInfo: rcp.TimeInfo): void {
    this.timeInfo = timeInfo;
  }

  /**
   * 仅供框架内部使用：发起取消，回发用户取消事件。
   */
  public emitCancel(): void {
    if (this.terminated) {
      return;
    }
    this.terminated = true;
    this.sendEvent(new QCloudTransferData(QCloudEventType.cancel, null, null));
    this.finish();
  }

  onResponseHeaders(headers: Record<string, string>): void {
    if (this.terminated) {
      return;
    }
    this.headerReceived = true;
    this.sendOrderEvent(new QCloudTransferData(QCloudEventType.headerReceive, headers, null), 0, 3);
  }

  onData(chunk: ArrayBuffer): void {
    if (this.terminated) {
      return;
    }
    this.sendEvent(new QCloudTransferData(QCloudEventType.dataReceive, chunk, null));
  }

  onProgress(completedBytes: number, totalBytes: number): void {
    if (this.terminated) {
      return;
    }
    this.progressController.updateProgress(completedBytes, totalBytes);
  }

  onComplete(statusCode: number): void {
    if (this.terminated) {
      return;
    }
    this.terminated = true;
    // 兜底：自定义实现未回调响应头时，补一个空响应头（order 0），
    // 避免有序缓冲区因缺少 order 0 而一直挂起 dataEnd/finish，导致任务永不结束。
    if (!this.headerReceived) {
      this.headerReceived = true;
      let emptyHeaders: Record<string, string> = {};
      this.sendOrderEvent(new QCloudTransferData(QCloudEventType.headerReceive, emptyHeaders, null), 0, 3);
    }
    // 先 dataEnd(order 1) 再 finish(order 2)，与原有事件顺序保持一致
    this.sendOrderEvent(new QCloudTransferData(QCloudEventType.dataEnd, null, null), 1, 3);
    this.sendOrderEvent(new QCloudTransferData(QCloudEventType.finish, statusCode, null, this.timeInfo), 2, 3);
    this.finish();
  }

  onFailure(error: Error): void {
    if (this.terminated) {
      return;
    }
    this.terminated = true;
    this.sendEvent(new QCloudTransferData(QCloudEventType.netError, null, error));
    this.finish();
  }
}
