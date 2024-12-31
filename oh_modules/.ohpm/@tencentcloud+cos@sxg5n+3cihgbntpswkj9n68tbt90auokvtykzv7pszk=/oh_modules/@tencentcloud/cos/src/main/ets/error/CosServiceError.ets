import { CosError, CosErrorType } from './CosError';
import { CosErrorCode } from './CosErrorCode';

/**
 * cos服务端error
 */
export class CosServiceError extends CosError {
  /**
   * 错误码，用来定位唯一的错误条件和确定错误场景
   */
  public code?: string;
  /**
   * 请求的资源，存储桶地址或对象地址
   */
  public resource?: string;
  /**
   * 每次请求发送时，服务端将会自动为请求生成一个 ID，遇到问题时，该 ID 能更快地协助 COS 定位问题
   */
  public requestId?: string;
  /**
   * 每次请求出错时，服务端将会自动为这个错误生成一个ID，遇到问题时，该 ID 能更快地协助 COS 定位问题
   */
  public traceId?: string;

  /**
   * http状态码
   */
  public httpCode: number;

  /**
   * http头
   */
  public header?: Record<string, string>


  constructor(httpCode: number, header?: Record<string, string>, requestId?: string, traceId?: string, code?: string, message?: string, resource?: string) {
    super(CosErrorType.Service, CosErrorCode.SERVICE_ERROR);
    this.name = httpCode.toString();
    this.httpCode = httpCode;
    this.code = code;
    this.resource = resource;
    this.requestId = requestId;
    this.traceId = traceId;
    this.header = header;

    if(message) {
      this.message = message;
    }
    if(code) {
      this.name = code;
    }
  }
}