import { CosClientError, CosError, CosErrorType, CosServiceError } from '@tencentcloud/cos'
import { Logger } from './Logger'

export function sizeFormat(size: number): string {
  if (size < 1024) {
    return size + 'B'
  }

  if (size < 1024 * 1024) {
    return (size / 1024).toFixed(2) + 'KB'
  }

  if (size < 1024 * 1024 * 1024) {
    return (size / 1024 / 1024).toFixed(2) + 'MB'
  }

  if (size < 1024 * 1024 * 1024 * 1024) {
    return (size / 1024 / 1024 / 1024).toFixed(2) + 'GB'
  }
  return size + '';
}

export function printError(error: CosError): string{
  if(error.type == CosErrorType.Service){
    let serviceError = error as CosServiceError;
    Logger.error(serviceError)
    return JSON.stringify(serviceError)
  } else {
    let clientError = error as CosClientError;
    let errString = `{
      "type": ${clientError.type},
      "code": ${clientError.cosErrorCode},
      "message": ${clientError.message},
      "detailErro": ${JSON.stringify(clientError.detail)},
    }`;
    Logger.error(errString)
    return errString;
  }
}