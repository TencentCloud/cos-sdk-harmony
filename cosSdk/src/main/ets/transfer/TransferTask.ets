import { CosXmlBaseService } from '../CosXmlBaseService';
import { ObjectRequest } from '../model/object/ObjectRequest';
import { Callback } from '@ohos.base';
import { HttpProgress, QCloudLogger, QCloudUserCancelError } from '@tencentcloud/foundation';
import { CosXmlRequest } from '../model/CosXmlRequest';
import { CosXmlResult } from '../model/CosXmlResult';
import { CosError } from '../error/CosError';
import { CosErrorUtils } from '../util/CosErrorUtils';
import { rcp } from '@kit.RemoteCommunicationKit';

export abstract class TransferTask<T1, T2> {
  protected cosXmlBaseService: CosXmlBaseService;
  protected objectRequest: T1;
  onResult: TransferResultListener<T1, T2> | undefined;
  onProgress: Callback<HttpProgress> | undefined;
  /**
   * 耗时信息回调
   */
  onTimeInfo?: (request: CosXmlRequest, timeInfo: rcp.TimeInfo)=>void;

  /**
   * 传输状态变化回调
   *
   * 状态流转：Waiting -> Processing -> Success / Error / Canceled，
   * 其中 Processing 可经 pause() 进入 Pause，再经 resume() 回到 Processing。
   */
  onState: Callback<TransferState> | undefined;

  protected state: TransferState = TransferState.Waiting;

  /**
   * 更新任务状态并通知外部。
   * 状态未发生变化时不重复回调；外部回调中的异常不影响传输本身。
   */
  protected updateState(state: TransferState) {
    if (this.state === state) {
      return;
    }
    this.state = state;
    if (this.onState) {
      try {
        this.onState(this.state);
      } catch (e) {
      }
    }
  }

  /**
   * 获取当前传输状态
   */
  public getState(): TransferState {
    return this.state;
  }

  /**
   * 仅当任务仍处于进行中时才置为 Error。
   *
   * pause()/cancel() 会取消在途请求，这些请求随后的失败回调不应把状态从
   * Pause/Canceled 覆写为 Error（否则外部会看到「暂停后又变失败」的错误跃迁）；
   * 已 Success 的任务同理不再变更。
   */
  protected markErrorIfActive() {
    if (this.state !== TransferState.Pause && this.state !== TransferState.Canceled &&
      this.state !== TransferState.Success) {
      this.updateState(TransferState.Error);
    }
  }

  constructor(cosXmlBaseService: CosXmlBaseService, cos: T1) {
    this.cosXmlBaseService = cosXmlBaseService;
    this.objectRequest = cos;
  }

  abstract start(): void;

  abstract pause(): void;

  abstract resume(): void;

  abstract cancel(): void;

  // 对外抛一次失败后，后续的失败不再调用（防止取消或者分块已经发出去的请求失败）
  private failed = false;

  /**
   * 复位失败标记，使任务可以再次对外抛出失败。
   *
   * 该标记的语义是「一次传输周期内只对外报一次失败」。由于 pause() 本身会走一次
   * onFail(CosTransferPauseError)，标记会被置位；若不在 resume() 时复位，
   * 恢复后再遇到真实失败将无法通知外部（onResult.onFail 静默不触发）。
   */
  protected resetFailedFlag() {
    this.failed = false;
  }

  /**
   * 对外错误收拢为CosError
   */
  protected onFail(request: T1, err: Error | CosError | QCloudUserCancelError) {
    QCloudLogger.error(err);
    if (this.onResult && !this.failed) {
      let cosError = CosErrorUtils.transformCosError(err);
      // 外部回调中的异常不做处理
      try {
        this.onResult?.onFail(request, cosError);
      } catch (e) {
      }
      this.failed = true;
    }
  }

  protected onSuccess(request: T1, result: T2) {
    if (this.onResult) {
      try {
        // 外部回调中的异常不做处理
        this.onResult?.onSuccess(request, result);
      } catch (e) {
      }
    }
  }
}

export interface TransferResultListener<T1, T2> {
  onSuccess: (request: T1, result: T2) => void;
  onFail: (request: T1, error: CosError) => void;
}

export enum TransferState {
  Waiting, Processing, Pause, Success, Canceled, Error
}