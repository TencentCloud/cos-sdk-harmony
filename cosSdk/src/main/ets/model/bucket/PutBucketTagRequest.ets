import { ObjectRequest } from '../object/ObjectRequest';
import http from '@ohos.net.http';
import { ContentType, RequestBodySerializer, XmlUtils } from '@tencentcloud/foundation';
import { CosInvalidArgumentError } from '../../error/CosInvalidArgumentError';
import { CosXmlRequest } from '../CosXmlRequest';
import { CosXmlServiceConfig } from '../../CosXmlServiceConfig';
import List from '@ohos.util.List';
import { TagObject } from '../object/PutObjectTagRequest';

/**
 * COS 支持为已存在的 Bucket 设置标签（Tag）。PUT Bucket tagging 接口用于为存储桶设置键值对作为存储桶标签，可以协助您管理已有的存储桶资源，并通过标签进行成本管理。
 *
 * 目前存储桶标签功能最多支持一个存储桶下设置50个不同的标签。
 * 如果已存在对象标签，调用此接口会覆盖掉已有的标签。
 *
 * 请查看 https://cloud.tencent.com/document/product/436/34838
 */
export class PutBucketTagRequest extends CosXmlRequest {
  /**
   * 标签集合
   */
  tagSet: List<TagObject>;

  public getPath(cosXmlServiceConfig: CosXmlServiceConfig): string {
    return '';
  }

  public getQueries(): Map<string, string|undefined>{
    this.addQuery("tagging", undefined);
    return this.queries;
  }

  constructor(bucket: string, tagSet: List<TagObject>) {
    super();
    this.bucket = bucket;
    this.tagSet = tagSet;
    this.isNeedMD5 = true;
  }

  public getBodySerializer(): RequestBodySerializer | undefined {
    let tagSet: object = new Object();
    tagSet["tag"] = this.tagSet;

    let tagging: object = new Object();
    tagging["tagSet"] = tagSet;

    let tagInput: object = new Object();
    tagInput["tagging"] = tagging;
    let bodyString = XmlUtils.obj2xml(tagInput, true) || "";
    return RequestBodySerializer.wrap(ContentType.XML, bodyString);
  }

  public getMethod(): http.RequestMethod {
    return http.RequestMethod.PUT;
  }
}






