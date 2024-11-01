import http from '@ohos.net.http';
import { HttpHeader, QCloudCredential, QCloudPriority, RequestBodySerializer } from '@tencentcloud/foundation';
import { CosXmlServiceConfig } from '../CosXmlServiceConfig';
import { Callback } from '@ohos.base';
import { CosError } from '../error/CosError';
import { COS_VERSION } from '../../../../Index';

export abstract class CosXmlRequest {
  public abstract getMethod(): http.RequestMethod;
  public abstract getPath(cosXmlServiceConfig: CosXmlServiceConfig): string;
  public abstract getBodySerializer(): RequestBodySerializer|undefined;

  public checkParameters(){
  }
  public getQueries(): Map<string, string|undefined>{
    return this.queries;
  }
  public getHeaders(): Map<string, string>{
    if(!this.headers.has(HttpHeader.USER_AGENT)){
      this.headers.set(HttpHeader.USER_AGENT, "cos-harmony-sdk-"+ COS_VERSION)
    }
    return this.headers;
  }
  priority:QCloudPriority = QCloudPriority.Normal;

  taskId?: number;

  /**
   * 设置请求头
   */
  protected headers: Map<string, string> = new Map();

  /**
   * 设置请求query
   */
  protected queries: Map<string, string|undefined> = new Map();

  /**
   * 设置不签名签名的header
   */
  noSignHeaderKeys: Set<string> = new Set();

  /**
   * 设置不参与签名的query.
   */
  noSignQueryKeys: Set<string> = new Set();

  /**
   * 请求体是否需要进行MD5，设置到请求头
   */
  isNeedMD5: boolean = false;

  /**
   * URL是否携带签名。默认由Header携带
   */
  isSignedInURL?: boolean = false;

  /**
   * 当前请求访问凭证。优先级高于 CosXmlBaseService -> credentialCallBack;
   */
  credential?: QCloudCredential;

  /**
   * 请求地域，用于构建请求URL，优先级高于 CosXmlBaseService-> config;
   */
  region?: string;

  /**
   * 存储桶名称，格式为 BucketName-APPID
   */
  bucket?:string;

  /**
   * 请求头响应回调
   */
  onHeaderReceive: Callback<Record<string, string>> | undefined;

  /**
   * 成功响应回调
   */
  onSuccess: Callback<object> | undefined;

  /**
   * 失败响应回调
   */
  onFailure: Callback<CosError> | undefined;

  /**
   * 添加一个请求头
   * @param key
   * @param value
   */
  addHeader(key: string, value: string): void {
    this.headers.set(key, value);
  }

  /**
   * 添加多个请求头
   * @param headers
   */
  addHeaders(headers: Map<string, string>): void {
    headers.forEach((value, key) => {
      this.headers.set(key, value);
    });
  }

  /**
   * 删除一个请求头
   * @param key
   */
  removeHeader(key: string): void {
    this.headers.delete(key);
  }

  /**
   * 添加一个query参数
   * @param key
   * @param value
   */
  addQuery(key: string, value?: string): void {
    this.queries.set(key, value);
  }

  /**
   * 添加多个query参数
   * @param queries
   */
  addQueries(queries: Map<string, string|undefined>): void {
    queries.forEach((value, key) => {
      this.queries.set(key, value);
    });
  }

  /**
   * 删除一个query
   * @param key
   */
  removeQuery(key: string): void {
    this.queries.delete(key);
  }

  /**
   * 设置不参与签名响应头
   * @param key
   */
  addNoSignHeaderKey(key: string): void {
    this.noSignHeaderKeys.add(key);
  }

  /**
   * 设置一组不参与签名响应头
   * @param noSignQueryKeys
   */
  addNoSignHeaderKeys(noSignQueryKeys: Set<string>): void {
    noSignQueryKeys.forEach((key) => {
      this.noSignHeaderKeys.add(key);
    });
  }

  /**
   * 设置不参与签名query
   * @param key
   */
  addNoSignQueryKey(key: string): void {
    this.noSignQueryKeys.add(key);
  }
  /**
   * 设置一组不参与签名query
   * @param noSignQueryKeys
   */
  addNoSignQueryKeys(noSignQueryKeys: Set<string>): void {
    noSignQueryKeys.forEach((key) => {
      this.noSignQueryKeys.add(key);
    });
  }

  /**
   * 设置签名信息
   */
  setSign(authorization: string, token?: string, tokenName: string = "x-cos-security-token"): void{
    this.addHeader(HttpHeader.AUTHORIZATION, authorization);
    if(token){
      this.addHeader(tokenName, token);
    }
  }
}