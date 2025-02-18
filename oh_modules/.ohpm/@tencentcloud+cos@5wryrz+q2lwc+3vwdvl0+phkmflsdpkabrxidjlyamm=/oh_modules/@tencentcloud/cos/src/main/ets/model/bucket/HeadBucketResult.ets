import { HttpHeader } from '@tencentcloud/foundation';
import { CosXmlResult } from '../CosXmlResult';

export class HeadBucketResult extends CosXmlResult {
  /**
   * 返回文件的 MD5 算法校验值.eTag 的值可以用于检查 Object 在上传过程中是否有损坏
   */
  requestId(): string|undefined {
    if(this.headers){
      return this.headers["x-cos-request-id"];
    }
    return undefined;
  }

  /**
   * 存储桶 AZ 类型，当存储桶为多 AZ 存储桶时返回此头部，值固定为 MAZ。
   * @returns
   */
  bucketAzType(): string|undefined{
    if(this.headers){
      return this.headers["x-cos-bucket-az-type"];
    }
    return undefined;
  }

  bucketRegion(): string|undefined{
    if(this.headers){
      return this.headers["x-cos-bucket-region"];
    }
    return undefined;
  }
}