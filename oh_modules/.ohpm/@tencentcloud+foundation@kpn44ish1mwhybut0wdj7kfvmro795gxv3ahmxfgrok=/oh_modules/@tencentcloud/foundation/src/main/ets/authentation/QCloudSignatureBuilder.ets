import { QCloudAuthenticationError } from '../error/QCloudAuthenticationError';
import { QCloudLogger } from '../logger/QCloudLogger';
import { HttpRequest } from '../net/HttpRequest';
import { QCloudHttpRequest } from '../net/QCloudHttpRequest';
import { CredentialCache } from './CredentialCache';
import { QCloudAuthentationCreator } from './QCloudAuthentationCreator';
import { QCloudCredential } from './QCloudCredential';
import { QCloudSignature } from './QCloudSignature';

export type SelfSignCallBack = <T>(reqeust:HttpRequest<T>) => Promise<void>;

export type CredentialCallBack = <T>(reqeust:HttpRequest<T>) => Promise<QCloudCredential>;

export class QCloudSignatureBuilder{
  public static async signatureBuild<T>(request:QCloudHttpRequest<T>):Promise<QCloudSignature|null>{
    return new Promise( async (resolve,reject)=>{
      let credential:QCloudCredential|null = null;
      // 凭证获取优先级：常量凭证>缓存凭证>回调获取
      if (request.credential){
        credential = request.credential;
      }else if (CredentialCache.singleCache().getCredential() != null && CredentialCache.singleCache().getCredential() != undefined){
        credential = CredentialCache.singleCache().getCredential()!;
      }else if(request.credentialCallBack){
        QCloudLogger.log("Credential_buildRequestData" + ":" + "getNewCredentialCallBack")
        try {
          setTimeout(()=>{reject(new QCloudAuthenticationError(Error("timeout getting temporary key")))}, 20 * 1000);
          credential = await request.credentialCallBack(request);
          CredentialCache.singleCache().cacheCredential(credential)
        } catch (e) {
          reject(new QCloudAuthenticationError(e))
        }
      }
      if(credential){
        try {
          let creator = new QCloudAuthentationCreator(credential);
          let signature = await creator.buildSignature(request)
          resolve(signature);
        } catch (e) {
          reject(new QCloudAuthenticationError(e))
        }
      } else {
        resolve(null);
      }
    })
  }
}