import { CosError, CosErrorType } from './CosError';
import { CosErrorCode } from './CosErrorCode';

/**
 * cos客户端error
 */
export class CosClientError extends CosError {
  public detail?: object;
  constructor(cosErrorCode: CosErrorCode, error?: object|string) {
    super(CosErrorType.Client, cosErrorCode);
    this.message = cosErrorCode.toString();
    this.name = cosErrorCode.toString();
    if(error){
      if(typeof error === 'string') {
        this.detail = new Error(error);
        this.message = error;
      } else if(error instanceof Error) {
        this.detail = error;
        this.message = error.message;
      } else {
        this.detail = error;
        this.message = JSON.stringify(this.detail);
      }
    }
  }
}