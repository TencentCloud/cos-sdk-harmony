import http from '@ohos.net.http';
import { RequestBodySerializer } from '@tencentcloud/foundation';
import { CosXmlRequest } from '../CosXmlRequest';
import { CosXmlServiceConfig } from '../../CosXmlServiceConfig';

/**
 * GET Bucket location 接口用于获取存储桶所在的地域信息。
 *
 * 请查看 https://cloud.tencent.com/document/product/436/8275
 */
export class GetBucketLocationRequest extends CosXmlRequest {
  public getPath(cosXmlServiceConfig: CosXmlServiceConfig): string {
    return '';
  }

  public getQueries(): Map<string, string | undefined> {
    this.addQuery("location", undefined);
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
