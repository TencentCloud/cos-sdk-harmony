import { ObjectRequest } from './ObjectRequest';
import http from '@ohos.net.http';
import { RequestBodySerializer } from '@tencentcloud/foundation';

/**
 * 获取 COS 对象的元数据信息(meta data)的方法.
 *
 * 获取 COS 对象的元数据信息，需要与 Get 的权限一致.且请求是不返回消息体的.若请求中需要设置If-Modified-Since 头部，
 * 则统一采用 GMT(RFC822) 时间格式，例如：Tue, 22 Oct 2017 01:35:21 GMT.如果对象不存在，则 返回404.
 *
 * 关于获取 COS 对象的元数据信息接口的具体描述，请查看https://cloud.tencent.com/document/product/436/7745
 */
export class HeadObjectRequest extends ObjectRequest {
  constructor(bucket: string, cosPath: string) {
    super(bucket, cosPath);
  }

  public getBodySerializer(): RequestBodySerializer|undefined {
    return undefined;
  }
  public getMethod(): http.RequestMethod {
    return http.RequestMethod.HEAD;
  }
}