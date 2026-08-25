/**
 * 自定义网络层响应回调接口。
 *
 * {@link NetworkProxy} 在执行请求的过程中，通过本接口把响应结果回调给 SDK 框架，
 * 框架据此驱动响应转换、进度回调、重试判定等逻辑。
 *
 * 调用约定：
 * 1. 顺序：先 {@link onResponseHeaders}，再零次或多次 {@link onData}，最后 {@link onComplete}；
 *    任意阶段出错则调用 {@link onFailure}。{@link onComplete} 与 {@link onFailure} 互斥、且只应调用一次。
 * 2. 大响应体（如大文件下载）应通过多次 {@link onData} 分片回调，避免一次性占用大量内存。
 * 3. 请在与 SDK 相同的线程（主线程）上调用这些方法；若在 worker 中执行网络请求，请自行 marshal 回主线程。
 */
export interface CustomNetworkResponseHandler {
  /**
   * 收到响应头时回调（此时可能尚未拿到最终状态码，状态码在 {@link onComplete} 中回传）。
   * @param headers 响应头
   */
  onResponseHeaders(headers: Record<string, string>): void;

  /**
   * 收到响应体分片时回调，可多次调用以支持流式下载。
   * @param chunk 响应体分片
   */
  onData(chunk: ArrayBuffer): void;

  /**
   * 上传 / 下载进度回调。
   * @param completedBytes 已传输字节数
   * @param totalBytes 总字节数
   */
  onProgress(completedBytes: number, totalBytes: number): void;

  /**
   * 请求成功结束时回调。
   * @param statusCode HTTP 状态码
   */
  onComplete(statusCode: number): void;

  /**
   * 请求失败时回调。
   * @param error 错误信息
   */
  onFailure(error: Error): void;
}
