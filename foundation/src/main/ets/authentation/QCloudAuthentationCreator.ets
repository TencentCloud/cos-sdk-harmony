import { QCloudCredential } from './QCloudCredential';
import { ArrayList} from '@kit.ArkTS';
import { CryptoUtil } from '../util/CryptoUtil';
import { QCloudSignature } from './QCloudSignature';
import { QCloudHttpRequest } from '../net/QCloudHttpRequest';
import { http } from '@kit.NetworkKit';

function camSafeUrlEncode(str:string) {
  return encodeURIComponent(str)
    .replace(/!/g, '%21')
    .replace(/'/g, '%27')
    .replace(/\(/g, '%28')
    .replace(/\)/g, '%29')
    .replace(/\*/g, '%2A');
}

function getSignParams(headers:Map<string,string|undefined>,noSign:Set<string>,isHeader:boolean):Map<string,string|undefined> {
  let tempHeaders = new Map<string,string|undefined>();
  let lowerCaseNoSign = new Set(Array.from(noSign, value => value.toLowerCase()));
  for (const item of headers.keys()) {
    let key = item.toLowerCase();
    if (isHeader){
      if (!lowerCaseNoSign.has(key)) {
        tempHeaders.set(item,headers.get(item)!);
      }
    }else{
      if (!lowerCaseNoSign.has(key)) {
        tempHeaders.set(item,headers.get(item)!);
      }
    }
  }
  return tempHeaders;
};

function getObjectKeys(obj: Map<string,string|undefined>): string[] {
  let list:string[] = [];
  for (let key of obj.keys()) {
    list.push(camSafeUrlEncode(key).toLowerCase());
  }

  list.sort((a:string, b:string) => {
    let aV = a.toLowerCase();
    let bV = b.toLowerCase();
    return aV === bV ? 0 : aV > bV ? 1 : -1;
  });

  return list;
}

function obj2str(obj: Map<string,string|undefined>, lowerCaseKey: boolean): string {
  let val: string;
  let list: string[] = [];
  for (const key of obj.keys()) {
    val = obj.get(key) === undefined || obj.get(key) === null ? '' : '' + obj.get(key);
    let tkey = lowerCaseKey ? camSafeUrlEncode(key).toLowerCase() : camSafeUrlEncode(key);
    val = camSafeUrlEncode(val) || '';
    list.push(tkey + '=' + val);
  }
  list.sort((a:string, b:string) => {
    let aV = a.toLowerCase();
    let bV = b.toLowerCase();
    return aV === bV ? 0 : aV > bV ? 1 : -1;
  });
  return list.join('&');
}

export class QCloudAuthentationCreator{

  private credential:QCloudCredential;

  public tokenName:string = "x-cos-security-token";

  excloudSignedList?:ArrayList<string>;

  constructor(credential:QCloudCredential) {
    this.credential = credential;
  }

  getCredential(){
    return this.credential;
  }

  setTokenName(tokenName:string){
    this.tokenName = tokenName;
  }

  async buildSignature<T>(httpRequest:QCloudHttpRequest<T>): Promise<QCloudSignature> {

    if (!this.credential || !this.credential.secretID || !this.credential.secretKey) {
      return new QCloudSignature();
    }
    if (this.credential.token) {
      if (httpRequest.isSignedInURL) {
        httpRequest.addQuery(this.tokenName,this.credential.token);
      }else{
        httpRequest.addHeader(this.tokenName,this.credential.token);
      }
    }
    const SecretId = this.credential.secretID;
    const SecretKey = this.credential.secretKey;
    const method = httpRequest?.method.toLowerCase();
    const queryParams:Map<string,string|undefined> = httpRequest?.queries || new Map<string,string>();
    const headerParams:Map<string,string> = httpRequest?.headers || new Map<string,string>();


    let now = new Date().getTime()/1000;
    if (this.credential.startDate) {
      now = this.credential.startDate.getTime()/1000;
    }

    let exp = now + 1800;

    if (this.credential.expirationDate) {
      exp = this.credential.expirationDate.getTime()/1000;
    }

    const qSignAlgorithm = 'sha1';
    const qAk = SecretId;
    const qSignTime = Math.floor(now) + ';' + Math.floor(exp);
    const qKeyTime = Math.floor(now) + ';' + Math.floor(exp);

    let headers = getSignParams(headerParams!,httpRequest.noSignHeaderKeys,true);
    let queries = getSignParams(queryParams!,httpRequest.noSignQueryKeys,false);

    if (this.credential.token ) {
      if (httpRequest.isSignedInURL) {
        queries.set(this.tokenName,this.credential.token);
      }else{
        headers.set(this.tokenName,this.credential.token);
      }
    }

    const qHeaderList = getObjectKeys(headers).join(';').toLowerCase();
    const qUrlParamList = getObjectKeys(queries).join(';').toLowerCase();

    // 签名算法说明文档：https://www.qcloud.com/document/product/436/7778
    // 步骤一：计算 SignKey
    const signKey = await CryptoUtil.qcloudHmacSha1(qKeyTime, SecretKey);

    let path = httpRequest.path;
    if (path.length == 0){
      path = '/';
    }else if (path.length > 0 && path.substring(0,1) != '/') {
      path = '/' + path;
    }
    if (path.includes("?")) {
      path = path.split("?")[0]
    }
    path = decodeURI(path);
    // 步骤二：构成 FormatString
    const formatString = [method, path, obj2str(queries, true), obj2str(headers, true), ''].join('\n');

    // 步骤三：计算 StringToSign
    const stringToSign = ['sha1', qSignTime, await CryptoUtil.qlcoudSha1(formatString), ''].join('\n');

    // 步骤四：计算 Signature
    const qSignature = await CryptoUtil.qcloudHmacSha1(stringToSign, signKey);

    // 步骤五：构造 Authorization
    const authorization = [
      'q-sign-algorithm=' + qSignAlgorithm,
      'q-ak=' + qAk,
      'q-sign-time=' + qSignTime,
      'q-key-time=' + qKeyTime,
      'q-header-list=' + qHeaderList,
      'q-url-param-list=' + qUrlParamList,
      'q-signature=' + qSignature,
    ].join('&');

    let signature = new QCloudSignature(authorization,this.credential.token);
    signature.tokenName = this.tokenName;
    return signature;
  }
}
