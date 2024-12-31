import { ObjectRequest } from '../object/ObjectRequest';
import http from '@ohos.net.http';
import { RequestBodySerializer } from '@tencentcloud/foundation';
import { CosXmlRequest, CosXmlServiceConfig } from '../../../../../Index';

/**
 * HEAD Bucket 请求可以确认该存储桶是否存在，是否有权限访问。有以下几种情况：
 *
 * HEAD Bucket 请求可以确认该存储桶是否存在，是否有权限访问。有以下几种情况：
 * 存储桶存在且有读取权限，返回 HTTP 状态码为200。
 * 无存储桶读取权限，返回 HTTP 状态码为403。
 * 存储桶不存在，返回 HTTP 状态码为404。
 *
 * 关于HEAD Bucket 接口具体描述，请查看https://cloud.tencent.com/document/product/436/7735
 */
export class HeadBucketRequest extends CosXmlRequest {
  public getPath(cosXmlServiceConfig: CosXmlServiceConfig): string {
    return "";
  }
  constructor(bucket: string) {
    super();
    this.bucket = bucket;
  }

  public getBodySerializer(): RequestBodySerializer|undefined {
    return undefined;
  }
  public getMethod(): http.RequestMethod {
    return http.RequestMethod.HEAD;
  }
}