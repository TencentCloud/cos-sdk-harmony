import http from '@ohos.net.http';
import { RequestBodySerializer, HttpProgress } from '@tencentcloud/foundation';
import { ObjectRequest } from './ObjectRequest';
import { Callback } from '@ohos.base';
import { TransferRequest } from './TransferRequest';

/**
 * 下载 COS 对象的方法.
 * 直接返回 ArrayBuffer
 *
 * 关于获取 COS 对象的接口描述，请查看 https://cloud.tencent.com/document/product/436/7753
 */
export class GetObjectArrayBufferRequest extends ObjectRequest implements TransferRequest {
  constructor(bucket: string, cosPath: string) {
    super(bucket, cosPath);
  }

  /**
   * 下载进度回调
   */
  onProgress?: Callback<HttpProgress>;

  public getBodySerializer(): RequestBodySerializer|undefined {
    return undefined;
  }
  public getMethod(): http.RequestMethod {
    return http.RequestMethod.GET;
  }
}