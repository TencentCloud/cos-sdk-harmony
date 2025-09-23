import util from '@ohos.util';
import { HttpRequest } from './HttpRequest';

export abstract class ResponseBodyConverter<T> {
  abstract headersReceive(header: Record<string, string>);
  abstract convertPart(arrayBuffer: ArrayBuffer);
  abstract convertEnd(httpCode: number): T;

  reset(request:HttpRequest<T>){

  }

  protected concatenateArrayBuffers(...buffers: ArrayBuffer[]): ArrayBuffer {
    let totalLength = 0;
    for (const buffer of buffers) {
      totalLength += buffer.byteLength;
    }

    const result = new Uint8Array(totalLength);
    let offset = 0;
    for (const buffer of buffers) {
      result.set(new Uint8Array(buffer), offset);
      offset += buffer.byteLength;
    }

    return result.buffer;
  }

  protected arrayBufferToString(buffer: ArrayBuffer): string {
    let textDecoder = util.TextDecoder.create('utf-8')
    return textDecoder.decodeWithStream(new Uint8Array(buffer))
  }
}

// export class ResponseStringConverter extends ResponseBodyConverter<string> {
//   headersReceive(header: Record<string, string>): void {
//   }
//   buffers: ArrayBuffer[] = [];
//   convertPart(arrayBuffer: ArrayBuffer): void {
//     this.buffers.push(arrayBuffer);
//   }
//
//   convertEnd(httpCode: number): string {
//     const combinedBuffer = this.concatenateArrayBuffers(...this.buffers);
//     const result = this.arrayBufferToString(combinedBuffer);
//     return result;
//   }
// }