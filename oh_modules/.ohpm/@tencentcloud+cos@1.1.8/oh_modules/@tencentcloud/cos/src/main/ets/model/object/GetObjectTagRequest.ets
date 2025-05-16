import { ObjectRequest } from './ObjectRequest';
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
export class GetObjectTagRequest extends ObjectRequest {
  /**
   * 当启用版本控制时，指定要操作的对象版本 ID，如不指定则将添加标签到最新版本的对象。
   */
  versionId?: string;

  constructor(bucket: string, objectKey: string, versionId?: string) {
    super(bucket, objectKey);
    this.versionId = versionId;
  }

  public getQueries(): Map<string, string | undefined> {
    this.addQuery('tagging', undefined);
    if (this.versionId) {
      this.addQuery('VersionId', this.versionId);
    }
    return this.queries;
  }

  public getBodySerializer(): RequestBodySerializer | undefined {
    return undefined;
  }

  public getMethod(): http.RequestMethod {
    return http.RequestMethod.GET;
  }
}






