import { ObjectRequest } from './ObjectRequest';
import http from '@ohos.net.http';
import { HttpHeader, RequestBodySerializer } from '@tencentcloud/foundation';
import { getCotnentType } from '../../common/Constants';

/**
 * 初始化分块上传的方法.
 *
 * 使用分块上传对象时，首先要进行初始化分片上传操作，获取对应分块上传的 uploadId，用于后续上传操作.分块上传适合于在弱网络或高带宽环境下上传较大的对象。
 *
 * 关于初始化分块上传的描述，请查看 https://cloud.tencent.com/document/product/436/7746
 */
export class InitMultipartUploadRequest extends ObjectRequest {
  public getBodySerializer(): RequestBodySerializer|undefined {
    return undefined;
  }
  public getMethod(): http.RequestMethod {
    return http.RequestMethod.POST;
  }

  public getHeaders(): Map<string, string>{
    if (!super.getHeaders().get(HttpHeader.CONTENT_TYPE)) {
      this.addHeader(HttpHeader.CONTENT_TYPE,getCotnentType(this.cosPath));
    }
    return this.headers;
  }

  public getQueries(): Map<string, string|undefined>{
    this.addQuery("uploads", undefined);
    return this.queries;
  }
}