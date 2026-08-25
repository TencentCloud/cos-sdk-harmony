import http from '@ohos.net.http';
import { ContentType, RequestBodySerializer, XmlUtils } from '@tencentcloud/foundation';
import { CosXmlRequest } from '../CosXmlRequest';
import { CosXmlServiceConfig } from '../../CosXmlServiceConfig';

/**
 * PUT Bucket versioning 接口用于实现存储桶多版本的开启或者暂停。
 *
 * 版本控制开启后，存储桶内的对象会保留历史版本，删除对象只会插入删除标记。
 * 注意：版本控制一旦开启，只能暂停（Suspended），无法关闭回未开启状态。
 *
 * 请查看 https://cloud.tencent.com/document/product/436/19889
 */
export class PutBucketVersioningRequest extends CosXmlRequest {
  /**
   * 是否开启版本控制，true 为 Enabled，false 为 Suspended
   */
  enableVersion: boolean;

  public getPath(cosXmlServiceConfig: CosXmlServiceConfig): string {
    return '';
  }

  public getQueries(): Map<string, string | undefined> {
    this.addQuery("versioning", undefined);
    return this.queries;
  }

  constructor(bucket: string, enableVersion: boolean) {
    super();
    this.bucket = bucket;
    this.enableVersion = enableVersion;
  }

  public getBodySerializer(): RequestBodySerializer | undefined {
    let versioningConfiguration: object = new Object();
    versioningConfiguration['status'] = this.enableVersion ? 'Enabled' : 'Suspended';

    let versioningInput: object = new Object();
    versioningInput['versioningConfiguration'] = versioningConfiguration;
    let bodyString = XmlUtils.obj2xml(versioningInput, true) || '';
    return RequestBodySerializer.wrap(ContentType.XML, bodyString);
  }

  public getMethod(): http.RequestMethod {
    return http.RequestMethod.PUT;
  }
}
