import { XmlUtils } from '../util/XmlUtils';
import { ContentType } from './HttpConstants';

export abstract class RequestBodySerializer {
  public abstract body(): string | ArrayBuffer | undefined;
  public abstract contentType(): string;
  public abstract contentLength(): number;
  public static wrap(contentType: string, body: string | ArrayBuffer | undefined): RequestBodySerializer {
    return new BaseRequestBodyWrapper(contentType, body);
  }
}

export class BaseRequestBodyWrapper extends RequestBodySerializer {
  bodyw: string | ArrayBuffer | undefined = undefined;
  contentTypew: string;

  constructor(contentType: string, body: string | ArrayBuffer | undefined) {
    super();
    this.bodyw = body;
    this.contentTypew = contentType;
  }

  contentType(): string {
    return this.contentTypew;
  }

  contentLength(): number {
    if (this.bodyw instanceof ArrayBuffer) {
      return this.bodyw.byteLength;
    }

    if (typeof this.bodyw == 'string') {
      return this.bodyw.length;
    }

    return 0;
  }

  body(): string | ArrayBuffer | undefined {
    return this.bodyw;
  }
}