/**
 * 基类error
 */
import { QCloudAuthenticationError, QCloudNetError, QCloudTaskError, QCloudUserCancelError } from '@tencentcloud/foundation';
import { CosClientError } from '../error/CosClientError';
import { CosError } from '../error/CosError';
import { CosErrorCode } from '../error/CosErrorCode';
import { CosServiceError } from '../error/CosServiceError';

export class CosErrorUtils {
  /**
   * 对外错误收拢为CosError
   */
  public static transformCosError(error: Error|CosError|QCloudUserCancelError): CosError{
    if(error instanceof QCloudAuthenticationError){
      return new CosClientError(CosErrorCode.INVALID_CREDENTIALS, error.error);
    } else if(error instanceof QCloudNetError){
      return new CosClientError(CosErrorCode.NETWORK, error.netError);
    } else if(error instanceof QCloudTaskError){
      return new CosClientError(CosErrorCode.TASK, error.taskError);
    } else if(error instanceof QCloudUserCancelError){
      return new CosClientError(CosErrorCode.USER_CANCELLED, error.message);
    } else if(error instanceof CosClientError){
      return error;
    } else if(error instanceof CosServiceError){
      return error;
    } else {
      return new CosClientError(CosErrorCode.UNKNOWN, error);
    }
  }
}