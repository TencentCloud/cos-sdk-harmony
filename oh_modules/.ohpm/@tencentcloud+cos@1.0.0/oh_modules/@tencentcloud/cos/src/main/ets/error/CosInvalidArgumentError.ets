import { CosClientError } from './CosClientError';
import { CosErrorCode } from './CosErrorCode';

export class CosInvalidArgumentError extends CosClientError {
  constructor(error: string) {
    super(CosErrorCode.INVALID_ARGUMENT, error);
  }
}
