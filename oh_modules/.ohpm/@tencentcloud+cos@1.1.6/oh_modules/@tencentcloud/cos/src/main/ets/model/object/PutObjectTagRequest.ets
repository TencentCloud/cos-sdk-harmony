import { ObjectRequest } from './ObjectRequest';
import http from '@ohos.net.http';
import { ContentType, RequestBodySerializer, XmlUtils } from '@tencentcloud/foundation';
import { CosInvalidArgumentError } from '../../error/CosInvalidArgumentError';
import { CosXmlRequest } from '../CosXmlRequest';
import { CosXmlServiceConfig } from '../../CosXmlServiceConfig';
import List from '@ohos.util.List';

/**
 * COS 支持为已存在的对象设置标签。PUT Object tagging 接口通过为对象添加键值对作为对象标签，可以协助您分组管理已有的对象资源，详情请参见 对象标签概述。
 *
 * 目前对象标签功能最多支持一个对象下设置10个不同的标签。
 * 如果已存在对象标签，调用此接口会覆盖掉已有的标签。
 *
 * 请查看 https://cloud.tencent.com/document/product/436/42997
 */
export class PutObjectTagRequest extends ObjectRequest {
  /**
   * 标签集合
   */
  tagSet?: List<TagObject>;
  /**
   * 当启用版本控制时，指定要操作的对象版本 ID，如不指定则将添加标签到最新版本的对象。
   */
  versionId?: string;

  constructor(bucket: string, objectKey: string, tagSet?: List<TagObject>, versionId?: string) {
    super(bucket, objectKey + "?tagging");
    this.tagSet = tagSet;
    this.versionId = versionId;
    this.isNeedMD5 = true;
  }

  public getQueries(): Map<string, string | undefined> {

    if (this.versionId) {
      this.addQuery('VersionId', this.versionId);
    }
    return this.queries;
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

export class TagObject {
  /**
   * 标签的 Key，不可为空，长度小于128字节, 支持英文字母、数字、空格、加号、减号、下划线、等号、点号、冒号、斜线
   */
  key?: string;
  /**
   * 标签的 Value，长度小于256字节, 支持英文字母、数字、空格、加号、减号、下划线、等号、点号、冒号、斜线
   */
  value?: string;

  constructor(key?: string, value?: string) {
    this.key = key;
    this.value = value;
  }
}





