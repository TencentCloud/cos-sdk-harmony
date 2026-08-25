import http from '@ohos.net.http';
import { RequestBodySerializer } from '@tencentcloud/foundation';
import { CosXmlRequest } from '../CosXmlRequest';
import { CosXmlServiceConfig } from '../../CosXmlServiceConfig';

/**
 * DELETE Bucket 接口请求可以在指定账号下删除一个存储桶。
 *
 * 删除存储桶前，请确保存储桶内的对象数量为0，即已删除存储桶内的所有对象、未完成的分块上传产生的碎片，
 * 否则会删除失败。
 *
 * 请查看 https://cloud.tencent.com/document/product/436/7732
 */
export class DeleteBucketRequest extends CosXmlRequest {
  public getPath(cosXmlServiceConfig: CosXmlServiceConfig): string {
    return '';
  }

  constructor(bucket: string) {
    super();
    this.bucket = bucket;
  }

  public getBodySerializer(): RequestBodySerializer | undefined {
    return undefined;
  }

  public getMethod(): http.RequestMethod {
    return http.RequestMethod.DELETE;
  }
}
