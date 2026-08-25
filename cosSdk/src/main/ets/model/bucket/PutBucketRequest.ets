import http from '@ohos.net.http';
import { ContentType, RequestBodySerializer, XmlUtils } from '@tencentcloud/foundation';
import { CosXmlRequest } from '../CosXmlRequest';
import { CosXmlServiceConfig } from '../../CosXmlServiceConfig';

/**
 * PUT Bucket 接口请求可以在指定账号下创建一个存储桶。
 *
 * 该 API 接口不支持匿名请求，您需要使用帯 Signature 签名认证的方式来调用该接口。
 * 创建存储桶时，您需要指定存储桶所在的地域，且存储桶名称在同一账号下必须唯一。
 *
 * 请查看 https://cloud.tencent.com/document/product/436/7738
 */
export class PutBucketRequest extends CosXmlRequest {
  /**
   * 是否创建多 AZ（多可用区）存储桶。
   * 开启后请求体为 <CreateBucketConfiguration><BucketAZConfig>MAZ</BucketAZConfig></CreateBucketConfiguration>，
   * 不开启则不携带请求体。
   */
  enableMAZ: boolean = false;

  public getPath(cosXmlServiceConfig: CosXmlServiceConfig): string {
    return '';
  }

  constructor(bucket: string) {
    super();
    this.bucket = bucket;
  }

  /**
   * 定义存储桶的访问控制列表（ACL）属性。
   * 枚举值请参见 ACL 概述 文档中存储桶的预设 ACL 部分，例如 private、public-read 等，默认为 private
   */
  public setXCosAcl(acl: string): void {
    this.addHeader('x-cos-acl', acl);
  }

  /**
   * 赋予被授权者读取存储桶的权限，格式为 id="[OwnerUin]"，例如 id="100000000001"
   */
  public setXCosGrantRead(grantRead: string): void {
    this.addHeader('x-cos-grant-read', grantRead);
  }

  /**
   * 赋予被授权者写入存储桶的权限，格式为 id="[OwnerUin]"，例如 id="100000000001"
   */
  public setXCosGrantWrite(grantWrite: string): void {
    this.addHeader('x-cos-grant-write', grantWrite);
  }

  /**
   * 赋予被授权者操作存储桶的所有权限，格式为 id="[OwnerUin]"，例如 id="100000000001"
   */
  public setXCosGrantFullControl(grantFullControl: string): void {
    this.addHeader('x-cos-grant-full-control', grantFullControl);
  }

  public getBodySerializer(): RequestBodySerializer | undefined {
    if (!this.enableMAZ) {
      return undefined;
    }

    let createBucketConfiguration: object = new Object();
    createBucketConfiguration['bucketAZConfig'] = 'MAZ';

    let bucketInput: object = new Object();
    bucketInput['createBucketConfiguration'] = createBucketConfiguration;
    let bodyString = XmlUtils.obj2xml(bucketInput, true) || '';
    return RequestBodySerializer.wrap(ContentType.XML, bodyString);
  }

  public getMethod(): http.RequestMethod {
    return http.RequestMethod.PUT;
  }
}
