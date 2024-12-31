import { CosXmlBaseService } from '../CosXmlBaseService';
import { ObjectRequest } from '../model/object/ObjectRequest';
import { Callback } from '@ohos.base';
import { HttpProgress, QCloudLogger, QCloudUserCancelError } from '@tencentcloud/foundation';
import { CosXmlRequest } from '../model/CosXmlRequest';
import { CosXmlResult } from '../model/CosXmlResult';
import { CosError } from '../error/CosError';
import { CosErrorUtils } from '../util/CosErrorUtils';

export abstract class TransferTask<T1, T2> {
  protected cosXmlBaseService: CosXmlBaseService;
  protected objectRequest: T1;
  onResult: TransferResultListener<T1, T2> | undefined;
  onProgress: Callback<HttpProgress> | undefined;

  // onState: Callback<TransferState> | undefined;

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