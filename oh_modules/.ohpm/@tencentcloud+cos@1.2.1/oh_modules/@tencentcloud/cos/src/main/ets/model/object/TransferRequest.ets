import { Callback } from '@ohos.base'
import { HttpProgress } from '@tencentcloud/foundation'

export interface TransferRequest {
  onProgress?:Callback<HttpProgress>;
}