import { HttpHeader, HttpRequest } from '@tencentcloud/foundation';
import { CosXmlResult } from '../model/CosXmlResult';
import { CosResponseBodyConverter } from './CosResponseBodyConverter';

/**
 * 响应解析到ArrayBuffer
 * 仅限getObject使用（因为逻辑中使用Content-Type进行服务端错误判断）
 */
export class ResponseArrayBufferConverter<T> extends CosResponseBodyConverter<T> {
  cosXmlResult: CosXmlResult;

  constructor(cosXmlResult: CosXmlResult) {
    super();
    this.cosXmlResult = cosXmlResult;
  }

  // 拿到header 因为http状态码最后才能拿到 需要跟进content type判断文件写入等
  header?: Record<string, string>;
  contentType = "";
  headersReceive(header: Record<string, string>): void {
    this.contentType = header[HttpHeader.RESPONSE_CONTENT_TYPE];
    this.header = header;
  }

  buffers: ArrayBuffer[] = [];
  convertPart(arrayBuffer: ArrayBuffer): void {
    this.buffers.push(arrayBuffer);
  }

  convertEnd(httpCode: number): T {
    let arrayBuffer = this.concatenateArrayBuffers(...this.buffers);
    if(this.contentType === "application/xml"){
      // xml响应 解析为服务端错误
      this.parseCosXmlError(httpCode, arrayBuffer, this.header);
    }
    this.cosXmlResult.parseResponseBody(httpCode, this.header!, arrayBuffer);
    return this.cosXmlResult as T;
  }

  reset(request: HttpRequest<T>): void {
    this.buffers = [];
  }
}