import { abilityDelegatorRegistry } from '@kit.TestKit';
import { CosClientError, CosServiceError, CosXmlBaseService, CosXmlRequest } from '../../../../../Index';
import { CosError, CosErrorType } from '../../../../main/ets/error/CosError';
import { Credential } from './Credential';
import { Logger } from './Logger';

export class TestUtils{
  public static getContext(): Context {
    let abilityDelegator = abilityDelegatorRegistry.getAbilityDelegator();
    return abilityDelegator.getAppContext().getApplicationContext();
  }

  public static getCosXmlBaseService(cosXmlBaseService?: CosXmlBaseService): CosXmlBaseService {
    if(cosXmlBaseService){
      return cosXmlBaseService;
    } else {
      return CosXmlBaseService.default();
    }
  }

  /**
   * 根据service判断是否单独设置request的凭证
   */
  public static async requestAddCredential(cosXmlRequest: CosXmlRequest, cosXmlBaseService: CosXmlBaseService): Promise<CosXmlRequest> {
    if(cosXmlBaseService.credentialCallBack){
      return cosXmlRequest;
    } else {
      let sessionCredential = await Credential.getSessionCredential();
      cosXmlRequest.credential = sessionCredential;
      return cosXmlRequest;
    }
  }

  public static trackError(error: CosError): Map<string, string|undefined>{
    let trackMap: Map<string, string|undefined> = new Map();
    // 错误类型（服务端和客户端）
    trackMap.set('type', error.type);
    // 错误码
    trackMap.set('code', error.cosErrorCode);
    // 错误信息
    trackMap.set('message', error.message);
    if(error.type == CosErrorType.Service){
      let serviceError = error as CosServiceError;
      // 服务端错误码 https://cloud.tencent.com/document/product/436/7730
      trackMap.set('serviceErrorCode', serviceError.code);
      // 服务端错误RequestId https://console.cloud.tencent.com/cos5/diagnose
      trackMap.set('serviceErrorRequestId', serviceError.requestId);
    } else {
      let clientError = error as CosClientError;
      // 客户端错误详情
      trackMap.set('clientErrorDetail', JSON.stringify(clientError.detail));
    }
    Logger.error(JSON.stringify(trackMap))
    return trackMap
  }

  public static printError(error: CosError): string{
    if(error.type == CosErrorType.Service){
      let serviceError = error as CosServiceError;
      Logger.error(serviceError)
      return JSON.stringify(serviceError)
    } else {
      let clientError = error as CosClientError;
      let errString = `{
      "type": ${clientError.type},
      "code": ${clientError.cosErrorCode},
      "message": ${clientError.message},
      "detailErro": ${JSON.stringify(clientError.detail)},
    }`;
      Logger.error(errString)
      return errString;
    }
  }
}