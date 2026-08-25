import http from '@ohos.net.http';
import { ContentType, RequestBodySerializer, XmlUtils } from '@tencentcloud/foundation';
import { CosXmlRequest } from '../CosXmlRequest';
import { CosXmlServiceConfig } from '../../CosXmlServiceConfig';

/**
 * PUT Bucket accelerate 接口用于为存储桶开启或关闭全球加速功能。
 *
 * 全球加速功能开启后，可以为存储桶提供就近接入、上传和下载加速的能力。
 *
 * 请查看 https://cloud.tencent.com/document/product/436/38869
 */
export class PutBucketAccelerateRequest extends CosXmlRequest {
  /**
   * 是否开启全球加速，true 为 Enabled，false 为 Suspended
   */
  enable: boolean;

  public getPath(cosXmlServiceConfig: CosXmlServiceConfig): string {
    return '';
  }

  public getQueries(): Map<string, string | undefined> {
    this.addQuery("accelerate", undefined);
    return this.queries;
  }

  constructor(bucket: string, enable: boolean) {
    super();
    this.bucket = bucket;
    this.enable = enable;
  }

  public getBodySerializer(): RequestBodySerializer | undefined {
    let accelerateConfiguration: object = new Object();
    accelerateConfiguration['status'] = this.enable ? 'Enabled' : 'Suspended';

    let accelerateInput: object = new Object();
    accelerateInput['accelerateConfiguration'] = accelerateConfiguration;
    let bodyString = XmlUtils.obj2xml(accelerateInput, true) || '';
    return RequestBodySerializer.wrap(ContentType.XML, bodyString);
  }

  public getMethod(): http.RequestMethod {
    return http.RequestMethod.PUT;
  }
}
