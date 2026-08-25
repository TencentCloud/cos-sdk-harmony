import http from '@ohos.net.http';
import { RequestBodySerializer } from '@tencentcloud/foundation';
import { CosXmlRequest } from '../CosXmlRequest';
import { CosXmlServiceConfig } from '../../CosXmlServiceConfig';

/**
 * GET Bucket accelerate 接口用于查询存储桶的全球加速功能配置。
 *
 * 请查看 https://cloud.tencent.com/document/product/436/38870
 */
export class GetBucketAccelerateRequest extends CosXmlRequest {
  public getPath(cosXmlServiceConfig: CosXmlServiceConfig): string {
    return '';
  }

  public getQueries(): Map<string, string | undefined> {
    this.addQuery("accelerate", undefined);
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
