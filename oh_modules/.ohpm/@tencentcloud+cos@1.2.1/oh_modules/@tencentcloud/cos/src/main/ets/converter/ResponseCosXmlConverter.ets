import { HttpRequest } from '@tencentcloud/foundation';
import { CosXmlResult } from '../model/CosXmlResult';
import { CosResponseBodyConverter } from './CosResponseBodyConverter';

export class ResponseCosXmlConverter<T> extends CosResponseBodyConverter<T> {
  cosXmlResult: CosXmlResult;

  constructor(cosXmlResult: CosXmlResult) {
    super();
    this.cosXmlResult = cosXmlResult;
  }

  header?: Record<string, string>;
  headersReceive(header: Record<string, string>): void {
    this.header = header;
  }

  buffers: ArrayBuffer[] = [];
  convertPart(arrayBuffer: ArrayBuffer): void {
    this.buffers.push(arrayBuffer);
  }

  convertEnd(httpCode: number): T {
    let arrayBuffer = this.concatenateArrayBuffers(...this.buffers);
    this.parseCosXmlError(httpCode, arrayBuffer, this.header);
    this.cosXmlResult.parseResponseBody(httpCode, this.header!, arrayBuffer);
    return this.cosXmlResult as T;
  }

  reset(request: HttpRequest<T>): void {
    this.buffers = [];
  }
}