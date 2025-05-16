import { HttpHeader } from '@tencentcloud/foundation';
import { CosXmlResult } from '../CosXmlResult';

export class HeadObjectResult extends CosXmlResult {
  /**
   * 返回文件的 MD5 算法校验值.eTag 的值可以用于检查 Object 在上传过程中是否有损坏
   */
  eTag(): string|undefined {
    if(this.headers){
      return this.headers[HttpHeader.ETAG];
    }
    return undefined;
  }

  cosObjectType(): string|undefined{
    if(this.headers){
      return this.headers["x-cos-object-type"];
    }
    return undefined;
  }

  cosStorageClass(): string|undefined{
    if(this.headers){
      return this.headers["x-cos-storage-class"];
    }
    return undefined;
  }
}