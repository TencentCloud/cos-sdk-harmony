import { ObjectRequest } from '../object/ObjectRequest';
import http from '@ohos.net.http';
import { ContentType, RequestBodySerializer, XmlUtils } from '@tencentcloud/foundation';
import { CosInvalidArgumentError } from '../../error/CosInvalidArgumentError';
import { CosXmlRequest } from '../CosXmlRequest';
import { CosXmlServiceConfig } from '../../CosXmlServiceConfig';
import List from '@ohos.util.List';

/**
 * COS 支持为已存在的存储桶查询标签（Tag）。GET Bucket tagging 接口用于查询指定存储桶下已有的存储桶标签。
 *
 * 请查看 https://cloud.tencent.com/document/product/436/34837
 */
export class GetBucketTagRequest extends CosXmlRequest {
  public getPath(cosXmlServiceConfig: CosXmlServiceConfig): string {
    return "";
  }

  public getQueries(): Map<string, string|undefined>{
    this.addQuery("tagging", undefined);
    return this.queries;
  }

  constructor(bucket: string) {
    super();
    this.bucket = bucket;
  }

  public getBodySerializer(): RequestBodySerializer | undefined {
    return undefined;
  }

  public getMethod(): http.RequestMethod {
    return http.RequestMethod.GET;
  }
}






