import { HttpHeader, RequestBodySerializer } from '@tencentcloud/foundation';
import { CosInvalidArgumentError } from '../../error/CosInvalidArgumentError';
import { CosXmlRequest } from '../CosXmlRequest';
import http from '@ohos.net.http';

/**
 * 生成对象预签名链接
 */
export class PresignedUrlRequest extends CosXmlRequest {
  public cosPath: string;
  public requestMethod: http.RequestMethod

  constructor(bucket: string, cosPath: string, requestMethod: http.RequestMethod = http.RequestMethod.GET) {
    super();
    this.bucket = bucket;
    this.cosPath = cosPath;
    this.requestMethod = requestMethod;

    this.isSignedInURL = true;
    this.addNoSignHeaderKey(HttpHeader.HOST);
    this.addNoSignHeaderKey(HttpHeader.USER_AGENT);
  }

  public getPath(): string {
    return this.cosPath;
  }

  public checkParameters(){
    super.checkParameters();
    if(!this.bucket){
      throw new CosInvalidArgumentError("bucket must not be null ");
    }
    if(!this.cosPath){
      throw new CosInvalidArgumentError("cosPath must not be null ");
    }
    if (this.cosPath.startsWith("/")) {
      throw new CosInvalidArgumentError("cosPath cannot start with /");
    }
  }

  public getMethod(): http.RequestMethod {
    return this.requestMethod;
  }

  public getBodySerializer(): RequestBodySerializer | undefined {
    return undefined;
  }
}