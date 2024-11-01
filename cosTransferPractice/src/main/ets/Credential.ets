import http from '@ohos.net.http';
import { CredentialCallBack, QCloudCredential } from '@tencentcloud/cos';
import { BusinessError } from '@ohos.base';
import { Logger } from './utils/Logger';
import { Const } from './Const';

export class Credential {
  /**
   * 获取STS临时秘钥
   */
  public static sessionCredential: CredentialCallBack = (request)=>{
    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      httpRequest.request(
        // 请替换为具体的sts临时密钥获取服务url
        Const.STS_CREDENTIAL_URL,
        { method: http.RequestMethod.GET },
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            Logger.info(data, "QCloudCredentials_Response")
            const stsSessionQCloudCredentials: StsSessionQCloudCredentials = JSON.parse(data.result.toString());
            let credential : QCloudCredential= new QCloudCredential();
            credential.secretID = stsSessionQCloudCredentials.credentials.tmpSecretId;
            credential.secretKey = stsSessionQCloudCredentials.credentials.tmpSecretKey;
            credential.token = stsSessionQCloudCredentials.credentials.sessionToken;
            credential.startDate = new Date(stsSessionQCloudCredentials.startTime * 1000);
            credential.expirationDate = new Date(stsSessionQCloudCredentials.expiredTime * 1000);
            httpRequest.destroy();
            resolve(credential)
          } else {
            Logger.info(`临时秘钥获取失败：`)
            Logger.error(err)
            httpRequest.destroy();
            reject(err)
          }
        });
    })
  }

  /**
   * 获取固定秘钥 仅在测试时使用
   */
  public static constCredential: CredentialCallBack = (request)=>{
    return new Promise((resolve, reject) => {
      let credential : QCloudCredential= new QCloudCredential();

      credential.secretID = Const.CONST_SECRET_ID;
      credential.secretKey = Const.CONST_SECRET_KEY;
      resolve(credential)
    })
  }
}

/**
 * 临时秘钥实体定义
 */
export class StsSessionQCloudCredentials{
  credentials: StsCredentials;
  startTime: number;
  expiredTime: number;

  constructor(credentials: StsCredentials, startTime: number, expiredTime: number) {
    this.credentials = credentials;
    this.startTime = startTime;
    this.expiredTime = expiredTime;
  }
}
export class StsCredentials{
  tmpSecretId: string;
  tmpSecretKey: string;
  sessionToken: string;

  constructor(tmpSecretId: string, tmpSecretKey: string, sessionToken: string) {
    this.tmpSecretId = tmpSecretId;
    this.tmpSecretKey = tmpSecretKey;
    this.sessionToken = sessionToken;
  }
}