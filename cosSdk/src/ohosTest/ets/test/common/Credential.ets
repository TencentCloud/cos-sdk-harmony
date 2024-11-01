import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';
import { Logger } from './Logger';
import { CredentialCallBack, QCloudCredential } from '@tencentcloud/foundation';
import { TestConst } from './TestConst';

export class Credential {
  /**
   * 临时秘钥
   */
  public static sessionCredential: CredentialCallBack = (request)=>{
    return Credential.getSessionCredential();
  }

  /**
   * 固定秘钥 仅在测试时使用
   */
  public static constCredential: CredentialCallBack = (request)=>{
    return new Promise((resolve, reject) => {
      let credential : QCloudCredential= new QCloudCredential();

      credential.secretID = TestConst.SECRET_ID;
      credential.secretKey = TestConst.SECRET_KEY;
      resolve(credential)
    })
  }

  public static async getSessionCredential(): Promise<QCloudCredential>{
    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      httpRequest.request(
        TestConst.STS_CREDENTIAL_URL,
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

  public static async getSignData(ext: string): Promise<SignData>{
    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      httpRequest.request(
        TestConst.SIGN_URL+'?ext='+ext,
        { method: http.RequestMethod.GET },
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            Logger.info(data, "getSignData_Response")

            let object: object = JSON.parse(data.result.toString());
            if(object['code'] == 0){
              const signData: SignData = new SignData(object['data']['cosKey'], object['data']['authorization'], object['data']['securityToken']);
              httpRequest.destroy();
              resolve(signData)
            } else {
              Logger.info(`临时秘钥获取失败：`)
              httpRequest.destroy();
              reject()
            }
          } else {
            Logger.info(`临时秘钥获取失败：`)
            Logger.error(err)
            httpRequest.destroy();
            reject(err)
          }
        });
    })
  }
}

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

export class SignData{
  cosKey: string;
  authorization: string;
  securityToken?: string;

  constructor(cosKey: string, authorization: string, securityToken?: string) {
    this.cosKey = cosKey;
    this.authorization = authorization;
    this.securityToken = securityToken;
  }
}