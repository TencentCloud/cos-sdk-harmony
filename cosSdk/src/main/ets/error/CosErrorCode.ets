/**
 * 错误码定义
 */
export enum CosErrorCode {
  /**
   * 服务端异常
   */
  SERVICE_ERROR = "CosServiceError",
  UNKNOWN = "Unknown Error",
  INVALID_ARGUMENT = "InvalidArgument",
  INVALID_CREDENTIALS = "InvalidCredentials",
  /**
   * 网络错误，参考 https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-net-http-0000001860176721
   */
  NETWORK = "NetworkError",
  TASK = "TaskError",
  USER_CANCELLED = "UserCancelled",
  USER_PAUSED = "UserPaused",
  /**
   * 数据格式错误，可能为服务端响应的数据不符合实体定义等
   */
  DATA_FORMAT = "DataFormat",
}