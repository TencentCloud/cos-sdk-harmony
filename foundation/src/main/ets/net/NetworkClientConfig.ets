/**
 * 网络客户端配置。
 *
 * 由 SDK 框架在初始化时通过 {@link NetworkClient#init} 注入，
 * 携带全局默认的超时时间与调试开关，供自定义网络实现参考使用。
 *
 * 注意：单次请求的超时时间以 {@link CustomNetworkRequest} 中的字段为准（可能被请求级配置覆盖）。
 * 本配置不含任何具体网络库（rcp）类型。
 */
export class NetworkClientConfig {
  /**
   * 连接超时时间，单位毫秒（ms）。
   */
  connectTimeoutMs: number;

  /**
   * 读取超时时间，单位毫秒（ms）。
   */
  readTimeoutMs: number;

  /**
   * 是否开启调试日志。
   */
  enableDebugLog: boolean;

  constructor(connectTimeoutMs: number = 15 * 1000, readTimeoutMs: number = 30 * 1000,
    enableDebugLog: boolean = false) {
    this.connectTimeoutMs = connectTimeoutMs;
    this.readTimeoutMs = readTimeoutMs;
    this.enableDebugLog = enableDebugLog;
  }
}
