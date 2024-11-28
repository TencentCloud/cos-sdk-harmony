import fs, { ReadOptions } from '@ohos.file.fs';
import { ContentType } from './HttpConstants';

import { RequestBodySerializer } from './RequestBodySerializer';

export class RequestFileBodyWrapper extends RequestBodySerializer {
  filePath :string;
  offset :number = 0;
  length :number = 0;
  constructor(file: string, offset: number, length: number) {
    super();
    this.filePath = file;
    this.offset = offset;
    this.length = length;
  }

  body(): ArrayBuffer {
    let file = fs.openSync(this.filePath,0);
    let state = fs.statSync(file.fd);
    if (this.length == 0) {
      this.length = state.size;
      this.offset = 0;
    }

    let arrayBuffer = new ArrayBuffer(this.length);
    let option: ReadOptions = {
      offset: this.offset,
      length: this.length
    };
    fs.readSync(file.fd,arrayBuffer,option);
    fs.closeSync(file);
    return arrayBuffer;
  }

  contentType(): string {
    return ContentType.OCTET_STREAM;
  }

  contentLength(): number {
    return this.length;
  }

}