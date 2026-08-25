import http from '@ohos.net.http';
import { RequestBodySerializer } from '@tencentcloud/foundation';
import { CosXmlRequest } from '../CosXmlRequest';
import { CosXmlServiceConfig } from '../../CosXmlServiceConfig';

/**
 * GET Bucket versioning 接口用于获取存储桶的版本控制信息。
 *
 * 请查看 https://cloud.tencent.com/document/product/436/19888
 */
export class GetBucketVersioningRequest extends CosXmlRequest {
  public getPath(cosXmlServiceConfig: CosXmlServiceConfig): string {
    return '';
  }

  public getQueries(): Map<string, string | undefined> {
    this.addQuery("versioning", undefined);
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
