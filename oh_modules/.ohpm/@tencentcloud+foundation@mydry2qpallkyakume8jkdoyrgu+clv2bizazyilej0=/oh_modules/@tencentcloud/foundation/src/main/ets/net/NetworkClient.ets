// /**
//  * 网络端 抽象类
//  */
// import { NetworkProxy } from './NetworkProxy';
//
// export abstract class NetworkClient {
//   // 网络client配置：日志开关、dns等, 后续复杂后考虑改为构建模式
//   protected enableDebugLog: boolean = false;
//   protected readTimeout: number = 30 * 1000;
//   protected connectTimeout: number = 15 * 1000;
//   protected dnsOverHttps: string | undefined;
//   protected dnsServers: Array<string> | undefined;
//
//   constructor(enableDebugLog?: boolean, readTimeout?: number, connectTimeout?: number, dnsOverHttps?: string | undefined,
//     dnsServers?: Array<string> | undefined) {
//     if(enableDebugLog){
//       this.enableDebugLog = enableDebugLog;
//     }
//     if(readTimeout){
//       this.readTimeout = readTimeout;
//     }
//     if(connectTimeout){
//       this.connectTimeout = connectTimeout;
//     }
//     this.dnsOverHttps = dnsOverHttps;
//     this.dnsServers = dnsServers;
//   }
//
//   abstract getNetworkProxy(): NetworkProxy;
// }