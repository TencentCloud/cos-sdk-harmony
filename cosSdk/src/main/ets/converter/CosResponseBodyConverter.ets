import { HttpHeader, ResponseBodyConverter, XmlUtils } from '@tencentcloud/foundation'
import { CosServiceError } from '../error/CosServiceError';

export abstract class CosResponseBodyConverter<T> extends ResponseBodyConverter<T> {
  protected parseCosXmlError(httpCode: number, buffer: ArrayBuffer, header?: Record<string, string>) {
    if(httpCode >= 200 && httpCode < 300)return;
    let requestId: string|undefined;
    let traceId: string|undefined;
    if(header){
      requestId = header[HttpHeader.X_COS_REQUEST_ID];
      traceId = header[HttpHeader.X_COS_TRACE_ID];
    }
    if(buffer && buffer.byteLength > 0){
      let tempError = XmlUtils.xml2obj(this.arrayBufferToString(buffer));
      let cosError:ServiceError|undefined;
      if (tempError) {
        cosError = tempError['error'] as ServiceError;
      }

      throw new CosServiceError(
        httpCode,
        header,
        requestId,
        traceId,
        cosError?.code,
        cosError?.message,
        cosError?.resource,
      );
    } else {
      throw new CosServiceError(httpCode, header, requestId, traceId);
    }
  }
}

class ServiceError {
  public code?: string;
  public message?: string;
  public resource?: string;
  public requestId?: string;
  public traceId?: string;
}