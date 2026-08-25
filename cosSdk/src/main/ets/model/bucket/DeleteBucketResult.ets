import { CosXmlResult } from '../CosXmlResult';

/**
 * DELETE Bucket 的返回结果，该接口无响应体，成功时返回 HTTP 状态码 204。
 */
export class DeleteBucketResult extends CosXmlResult {
  requestId(): string | undefined {
    if (this.headers) {
      return this.headers["x-cos-request-id"];
    }
    return undefined;
  }
}
