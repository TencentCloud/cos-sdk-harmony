// /**
//  * 鸿蒙自带网络端 实现
//  */
// import { HarmonyProxy } from './HarmonyProxy';
// import { NetworkClient } from './NetworkClient';
// import { NetworkProxy } from './NetworkProxy';
//
// export class HarmonyHttpClientImpl extends NetworkClient {
//   constructor(enableDebugLog?: boolean, readTimeout?: number, connectTimeout?: number,
//     dnsOverHttps?: string | undefined, dnsServers?: string[] | undefined) {
//     super(enableDebugLog, readTimeout, connectTimeout, dnsOverHttps, dnsServers);
//   }
//
//   getNetworkProxy(): NetworkProxy {
//     return new HarmonyProxy();
//   }
// }