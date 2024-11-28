import { ObjectRequest } from './ObjectRequest';
import http from '@ohos.net.http';
import { getCotnentType } from '../../common/Constants';
import {
  BaseRequestBodyWrapper,
  ContentType,
  HttpHeader,
  HttpProgress, RequestBodySerializer, RequestFileBodyWrapper } from '@tencentcloud/foundation';
import { TransferRequest } from './TransferRequest';
import { Callback } from '@ohos.base';
import { CosInvalidArgumentError } from '../../error/CosInvalidArgumentError';
import { PicOperations } from '../pic/PicOperations';

/**
 * 简单上传的方法.
 *
 * 简单上传主要适用于在单个请求中上传一个小于 5 GB 大小的对象. 对于大于 5 GB 的对象(或者在高带宽或弱网络环境中）优先使用分片上传的方式
 */
export class PutObjectRequest extends ObjectRequest implements TransferRequest {
  public getBodySerializer(): RequestBodySerializer | undefined {
    if (typeof this.body == 'string'){
      let serializer = new RequestFileBodyWrapper(this.getBody() as string,0,0);
      return serializer;
    }else if ( this.body instanceof ArrayBuffer ){
      let serializer = new BaseRequestBodyWrapper(ContentType.OCTET_STREAM,this.body);
      return serializer;
    }else{
      return undefined;
    }
  }

  body?:string | ArrayBuffer | undefined;

  constructor(bucket: string, cosPath: string, body:string | ArrayBuffer | undefined) {
    super(bucket, cosPath);
    this.body = body;
    this.isNeedMD5 = true;
  }

  onProgress?: Callback<HttpProgress>;

  public getHeaders(): Map<string, string>{
    if (!super.getHeaders().get(HttpHeader.CONTENT_TYPE)) {
      this.addHeader(HttpHeader.CONTENT_TYPE,getCotnentType(this.cosPath));
    }
    return this.headers;
  }

  public getQueries(): Map<string, string|undefined>{
    return this.queries;
  }

  public checkParameters(){
    super.checkParameters();
    if (!this.body) {
      throw new CosInvalidArgumentError('body is null');
    }
  }

  public getBody(): string | ArrayBuffer | undefined {
    return this.body;
  }
  public getMethod(): http.RequestMethod {
    return http.RequestMethod.PUT;
  }

  /**
   * 设置万象图片参数
   * @param picOperations 万象图片参数
   */
  public setPicOperations(picOperations: PicOperations){
    this.addHeader("Pic-Operations", JSON.stringify(picOperations));
  }
}