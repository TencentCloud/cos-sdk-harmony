/**
 * 自定义网络层请求数据。
 *
 * 这是交给 {@link NetworkProxy} 执行的纯粹请求描述，不包含任何具体网络库（如 rcp）的类型，
 * 便于客户使用自己的网络栈（@ohos.net.http、第三方库等）实现自定义网络层。
 *
 * 请求在交到这里之前，SDK 已完成签名、域名切换、请求头/请求体构建，
 * 自定义实现只需按这些字段发起 HTTP 请求即可。
 */
export class CustomNetworkRequest {
  /**
   * 任务标识，用于日志与关联，无需回传。
   */
  taskId: number = 0;

  /**
   * 请求方法，如 'GET' | 'PUT' | 'POST' | 'DELETE' | 'HEAD'。
   */
  method: string = 'GET';

  /**
   * 完整请求 URL（已签名、已按需切换为备用域名）。
   */
  url: string = '';

  /**
   * 请求头（已包含 Authorization、Host、Content-Type、Content-Length 等）。
   */
  headers: Record<string, string> = {};

  /**
   * 请求体，已物化为内存数据（文件上传分片也是内存 buffer）；无请求体时为 undefined。
   */
  body?: ArrayBuffer | string;

  /**
   * 连接超时时间，单位毫秒（ms）。
   */
  connectTimeoutMs: number = 15 * 1000;

  /**
   * 读取超时时间，单位毫秒（ms）。
   */
  readTimeoutMs: number = 30 * 1000;

  /**
   * 仅供 SDK 默认网络实现（基于 rcp）使用的原生高级配置。
   *
   * 该字段透传 CosXmlServiceConfig.requestConfiguration / dnsConfiguration 等原生配置，
   * 类型为 rcp.Configuration。自定义网络实现请忽略此字段。
   */
  nativeRequestConfiguration?: object;
}
