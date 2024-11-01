import { CosClientError } from './CosClientError';
import { CosErrorCode } from './CosErrorCode';

export class CosTransferPauseError extends CosClientError {
  constructor() {
    super(CosErrorCode.USER_PAUSED, "user pause");
  }
}
