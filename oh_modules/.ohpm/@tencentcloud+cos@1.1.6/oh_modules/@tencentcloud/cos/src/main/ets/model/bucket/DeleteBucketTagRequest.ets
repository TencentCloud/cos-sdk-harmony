import { ObjectRequest } from '../object/ObjectRequest';
import http from '@ohos.net.http';
import { ContentType, RequestBodySerializer, XmlUtils } from '@tencentcloud/foundation';
import { CosInvalidArgumentError } from '../../error/CosInvalidArgumentError';
import { CosXmlRequest } from '../CosXmlRequest';
import { CosXmlServiceConfig } from '../../CosXmlServiceConfig';
import List from '@ohos.util.List';

/**
 * COS 支持为已存在的 Bucket 删除标签（Tag）。DELETE Bucket tagging 接口用于删除指定存储桶下已有的存储桶标签。
 *
 * 请查看 https://cloud.tencent.com/document/product/436/34836
 */
export class DeleteBucketTagRequest extends CosXmlRequest {
  public getPath(cosXmlServiceConfig: CosXmlServiceConfig): string {
    return '?tagging';
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






