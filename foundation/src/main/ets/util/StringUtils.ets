import util from '@ohos.util';

export class StringUtils {

  /**
   * Uint8Array 转  String
   * @param input
   */
  static uint8Array2String(input: Uint8Array):string {
    if (!input) {
      return "";
    }
    let result = '';
    for (const item of input) {
      result += `${item.toString(16).padStart(2, '0')}`;
    }
    return result;
  }
  /**
   * ArrayBuffer 转  String
   * @param input
   * @returns
   */
  static arrayBuffer2String(input: ArrayBuffer) :string{
    let textDecoder = util.TextDecoder.create('utf-8')
    return textDecoder.decodeWithStream(new Uint8Array(input))
  }

  static parseInt(obj:string|number|undefined):number{
    if (typeof obj === 'string') {
      return parseInt(obj);
    }
    if (typeof obj === 'number') {
      return obj;
    }
    return 0;
  }

  static parseBool(obj:string|number|boolean|undefined):boolean{
    if (typeof obj == 'string') {
      return obj.toLowerCase() == 'true';
    }
    if (typeof obj === 'number') {
      return obj > 0;
    }
    if (typeof obj === 'boolean') {
      return obj;
    }
    return obj !== undefined && obj !== null;
  }
}
