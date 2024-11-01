/**
 * 腾讯云网络请求类，封装了签名等操作
 */
import { HttpRequest } from './HttpRequest';
import http from '@ohos.net.http';
import { ResponseBodyConverter } from './ResponseBodyConverter';
import { RequestBodySerializer } from './RequestBodySerializer';
import { QCloudCredential } from '../authentation/QCloudCredential';
import { CredentialCallBack, SelfSignCallBack } from '../authentation/QCloudSignatureBuilder';

export class QCloudHttpRequest<T> extends HttpRequest<T> {
  credential?:QCloudCredential;
  credentialCallBack?: CredentialCallBack;
  selfSignCallBack?: SelfSignCallBack;

  constructor(method: http.RequestMethod, protocol: string, host: string, port: number, path: string,
    requestBodySerializer: RequestBodySerializer|undefined, responseBodyConverter: ResponseBodyConverter<T>,
    headers?: Map<string, string>, queries?: Map<string, string|undefined>,isNeedMD5?:boolean, isSignedInURL?: boolean) {
    super(method, protocol, host, port, path, requestBodySerializer, responseBodyConverter, headers, queries,isNeedMD5, isSignedInURL);
  }
}