import { ObjectRequest } from './ObjectRequest';
import http from '@ohos.net.http';
import { RequestBodySerializer } from '@tencentcloud/foundation';

/**
 * 删除 COS 上单个对象的方法.
 *
 * COS 支持直接删除一个或多个对象，当仅需要删除一个对象时,只需要提供对象的名称（即对象键)即可.
 * 关于删除 COS 上单个对象的具体描述，请查看 https://cloud.tencent.com/document/product/436/7743
 */
export class DeleteObjectRequest extends ObjectRequest {
  constructor(bucket: string, cosPath: string) {
    super(bucket, cosPath);
  }

  public getBodySerializer(): RequestBodySerializer|undefined {
    return undefined;
  }
  public getMethod(): http.RequestMethod {
    return http.RequestMethod.DELETE;
  }
}