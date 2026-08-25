import { CosXmlResult } from '../CosXmlResult';

/**
 * PUT Bucket 的返回结果，该接口无响应体，成功时返回 HTTP 状态码 200。
 */
export class PutBucketResult extends CosXmlResult {
  requestId(): string | undefined {
    if (this.headers) {
      return this.headers["x-cos-request-id"];
    }
    return undefined;
  }
}
