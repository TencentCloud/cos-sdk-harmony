import { ObjectRequest } from './ObjectRequest';
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
export class DeleteObjectTagRequest extends ObjectRequest {
  /**
   * 当启用版本控制时，指定要操作的对象版本 ID，如不指定则将添加标签到最新版本的对象。
   */
  versionId?: string;

  constructor(bucket: string, objectKey: string, versionId?: string) {
    super(bucket, objectKey + "?tagging");
    this.versionId = versionId;
  }

  public getQueries(): Map<string, string | undefined> {

    if (this.versionId) {
      this.addQuery('VersionId', this.versionId);
    }
    return this.queries;
  }

  public getBodySerializer(): RequestBodySerializer | undefined {
    return undefined;
  }

  public getMethod(): http.RequestMethod {
    return http.RequestMethod.DELETE;
  }
}






