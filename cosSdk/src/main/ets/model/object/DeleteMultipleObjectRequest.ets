import { ObjectRequest } from './ObjectRequest';
import http from '@ohos.net.http';
import { ContentType, RequestBodySerializer, XmlUtils } from '@tencentcloud/foundation';
import { CosInvalidArgumentError } from '../../error/CosInvalidArgumentError';
import List from '@ohos.util.List';

/**
 * DELETE Multiple Objects 接口请求可以批量删除指定存储桶中的多个对象（Object），单次请求支持最多删除1000个对象。
 * 请查看 https://cloud.tencent.com/document/product/436/8289
 */
export class DeleteMultipleObjectRequest extends ObjectRequest {
  /**
   * 布尔值，默认为 false
   * true 为使用 Quiet 模式，在响应中仅包含删除失败的对象信息和错误信息
   * false 为使用 Verbose 模式，在响应中包含每个对象的删除结果
   */
  quiet?: boolean;

  /**
   * 要删除的目标对象的信息
   */
  objects?: List<DeleteObject>;

  public checkParameters(): void {
    if (!this.bucket) {
      throw new CosInvalidArgumentError("bucket must not be null ");
    }
  }

  constructor(bucket: string) {
    super(bucket, "");
    this.isNeedMD5 = true;
  }

  public getPath(): string {
    let path = super.getPath();
    return path + '?delete';
  }

  public getBodySerializer(): RequestBodySerializer | undefined {
    let deleteObj: object = new Object();
    deleteObj["quiet"] = this.quiet || false;
    deleteObj["object"] = this.objects;
    let input: object = new Object();
    input["delete"] = deleteObj;
    let bodyString = XmlUtils.obj2xml(input,true) || "";
    return RequestBodySerializer.wrap(ContentType.XML, bodyString);
  }

  public getMethod(): http.RequestMethod {
    return http.RequestMethod.POST;
  }
}

export class DeleteObject {
  /**
   * 要删除的目标对象的对象键
   */
  key?: string;

  /**
   * 当启用版本控制并且要删除对象的指定版本时需指定该元素，值为要删除的版本 ID。若未开启版本控制或开启版本控制但需要插入删除标记，则无需指定该元素
   */
  versionId?: string;

  constructor(key?: string,versionId?: string) {
    this.key = key;
    this.versionId = versionId;
  }
}