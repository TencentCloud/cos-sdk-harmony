import { CosXmlResult } from '../CosXmlResult';

export class GetObjectArrayBufferResult extends CosXmlResult {

  /**
   * 文件体
   */
  arrayBuffer?: ArrayBuffer;
  contentParser(arrayBuffer: ArrayBuffer){
    super.contentParser(arrayBuffer);
    this.arrayBuffer = arrayBuffer;
  }
}