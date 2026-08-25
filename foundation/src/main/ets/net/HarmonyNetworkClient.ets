import { NetworkClient } from './NetworkClient';
import { NetworkProxy } from './NetworkProxy';
import { HarmonyNetworkProxy } from './HarmonyNetworkProxy';

/**
 * 默认网络客户端：基于 HarmonyOS RemoteCommunicationKit（rcp）。
 *
 * 客户未通过 CosXmlServiceConfig.networkClient 指定自定义网络层时，SDK 使用本实现，
 * 行为与旧版本一致。
 */
export class HarmonyNetworkClient extends NetworkClient {
  getNetworkProxy(): NetworkProxy {
    return new HarmonyNetworkProxy();
  }
}
