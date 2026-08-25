import { NetworkClientConfig } from './NetworkClientConfig';
import { NetworkProxy } from './NetworkProxy';

/**
 * 网络客户端：网络层的「配置 + 工厂」。
 *
 * 一个 {@link NetworkClient} 在一个 CosXmlBaseService 实例内共享（配置在 CosXmlServiceConfig 上，
 * 由框架在 service 初始化时调用一次 {@link init}）；每次请求（含重试的每一次）通过
 * {@link getNetworkProxy} 产出一个新的 {@link NetworkProxy} 执行器。
 *
 * 不建议将同一个 NetworkClient 实例复用于多个 CosXmlBaseService（各 service 会分别调用其 init，
 * 后者的配置可能覆盖前者）。如需多个 service，请分别创建 NetworkClient 实例。
 *
 * 自定义网络层需要继承本类并实现 {@link getNetworkProxy}，
 * 通过 CosXmlServiceConfig.networkClient 注入。不设置时 SDK 使用默认实现 HarmonyNetworkClient。
 *
 * 用法：
 *   let config = new CosXmlServiceConfig("ap-guangzhou");
 *   config.networkClient = new MyNetworkClient();
 */
export abstract class NetworkClient {
  /**
   * 框架注入的网络配置（超时、调试开关等）。在 {@link init} 后可用。
   */
  protected config?: NetworkClientConfig;

  /**
   * 由 SDK 框架调用，注入网络配置。子类如需自定义可重写（重写时请调用 super.init）。
   * @param config 网络配置
   */
  init(config: NetworkClientConfig): void {
    this.config = config;
  }

  /**
   * 为一次请求产出一个网络执行代理。每次请求都会调用一次。
   */
  abstract getNetworkProxy(): NetworkProxy;
}
