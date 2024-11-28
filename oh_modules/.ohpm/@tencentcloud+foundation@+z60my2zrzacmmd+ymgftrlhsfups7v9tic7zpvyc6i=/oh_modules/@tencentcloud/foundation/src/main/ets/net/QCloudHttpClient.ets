// /**
//  * 网络端 对外
//  */
// import { QCloudSignatureBuilder } from '../authentation/QCloudSignatureBuilder';
// import { QCloudHTTPTask } from '../task/http/QCloudHTTPTask';
// import { QCloudRequestData } from '../task/http/QCloudRequestData';
// import { HarmonyHttpClientImpl } from './HarmonyHttpClientImpl';
// import { NetworkClient } from './NetworkClient';
// import { QCloudHttpRequest } from './QCloudHttpRequest';
//
// export class QCloudHttpClient {
//   private static K_CLIENT_ID = 33333;
//   public static readonly HTTP_LOG_TAG = "QCloudHttp";
//   private static clientMap: Map<string, NetworkClient> = new Map();
//
//   public static executeHttpRequest(qcloudRequestData: QCloudRequestData){
//     // if(qcloudRequestData.networkClientId){
//     //   QCloudHttpClient.clientMap.get(qcloudRequestData.networkClientId)?.getNetworkProxy().executeHttpRequest(qcloudRequestData);
//     // }
//     let harmonyHttpClientImpl = new HarmonyHttpClientImpl();
//     harmonyHttpClientImpl.getNetworkProxy().executeHttpRequest(qcloudRequestData);
//   }
//
//   clientId: string;
//   harmonyHttpClientImpl: HarmonyHttpClientImpl;
//
//   constructor(enableDebugLog?: boolean, readTimeout?: number, connectTimeout?: number,
//     dnsOverHttps?: string | undefined, dnsServers?: string[] | undefined) {
//     this.harmonyHttpClientImpl = new HarmonyHttpClientImpl(enableDebugLog, readTimeout, connectTimeout, dnsOverHttps, dnsServers);
//     this.clientId = (QCloudHttpClient.K_CLIENT_ID ++).toString();
//     QCloudHttpClient.clientMap.set(this.clientId, this.harmonyHttpClientImpl);
//   }
//
//   // public resolveRequest<T>(request: QCloudHttpRequest<T>, signatureBuilder?:QCloudSignatureBuilder): QCloudHTTPTask<object> {
//   //   return new QCloudHTTPTask(request, this.clientId, signatureBuilder);
//   // }
// }