import { StringUtils, XmlUtils } from '@tencentcloud/foundation';
import { CosXmlResult } from '../CosXmlResult';
import List from '@ohos.util.List';

export class DeleteMultipleObjectResult extends CosXmlResult {
  deleteMultipleObject?: DeleteMultipleObject;

  contentParser(arrayBuffer: ArrayBuffer) {
    super.contentParser(arrayBuffer);
    if (arrayBuffer) {
      let result = XmlUtils.xml2obj(StringUtils.arrayBuffer2String(arrayBuffer))
      if (result && result['deleteResult']) {
        this.deleteMultipleObject = DeleteMultipleObject.initWithJson(result['deleteResult']);
      }
    }
  }
}

export class DeleteMultipleObject {
  /**
   * 单个删除成功的对象条目，仅当使用 Verbose 模式才会返回该元素
   */
  deleted?: List<DeletedResult>;
  /**
   * 单个删除失败的对象条目
   */
  error?: List<ErrorResult>;

  public static initWithJson(json: object): DeleteMultipleObject {
    let result = new DeleteMultipleObject();

    let deleted: object = json['deleted'];
    let error: object = json['error'];

    let deletedResult = new List<DeletedResult>();
    let errorResult = new List<ErrorResult>();

    if (deleted) {
      if (Array.isArray(deleted) || (deleted instanceof List)) {
        for (const item of deleted as List<object>) {
          deletedResult.add(DeletedResult.initWithJson(item));
        }
      } else {
        deletedResult.add(DeletedResult.initWithJson(deleted));
      }
    }

    if (error) {
      if (Array.isArray(error) || (error instanceof List)) {
        for (const item of error as List<object>) {
          errorResult.add(ErrorResult.initWithJson(item));
        }
      } else {
        errorResult.add(ErrorResult.initWithJson(error));
      }
    }

    result.deleted = deletedResult;
    result.error = errorResult;

    return result;
  }
}

export class DeletedResult {
  /**
   * 删除成功的对象的对象键
   */
  key?: string;
  /**
   * 仅当对该对象的删除创建了一个删除标记，或删除的是该对象的一个删除标记时才返回该元素，布尔值，固定为 true
   */
  deleteMarker?: boolean;
  /**
   * 仅当对该对象的删除创建了一个删除标记，或删除的是该对象的一个删除标记时才返回该元素，值为创建或删除的删除标记的版本 ID
   */
  deleteMarkerVersionId?: string;
  /**
   * 删除成功的版本 ID，仅当请求中指定了要删除对象的版本 ID 时才返回该元素
   */
  versionId?: string;

  public static initWithJson(json: object): DeletedResult {
    let result = new DeletedResult();
    result.key = json['key'];
    result.deleteMarker = StringUtils.parseBool(json['deleteMarker']);
    if (json['deleteMarkerVersionId'] !== 'null') {
      result.deleteMarkerVersionId = json['deleteMarkerVersionId'];
    }else{
      result.deleteMarkerVersionId = undefined;
    }
    result.versionId = json['versionId'];
    return result;
  }
}

export class ErrorResult {
  /**
   * 删除失败的对象的对象键
   */
  key?: string;
  /**
   * 删除失败的版本 ID，仅当请求中指定了要删除对象的版本 ID 时才返回该元素
   */
  versionId?: string;
  /**
   * 删除失败的错误码，用来定位唯一的错误条件和确定错误场景
   */
  code?: string;
  /**
   * 删除失败的具体错误信息
   */
  message?: string;

  public static initWithJson(json: object): ErrorResult {
    let result = new ErrorResult();
    result.key = json['key'];
    result.versionId = json['versionId'];
    result.code = json['code'];
    result.message = json['message'];
    return result;
  }
}