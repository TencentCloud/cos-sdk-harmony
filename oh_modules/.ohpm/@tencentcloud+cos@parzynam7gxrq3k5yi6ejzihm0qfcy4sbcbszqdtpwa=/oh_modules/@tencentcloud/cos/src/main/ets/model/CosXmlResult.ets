
export abstract class CosXmlResult {
  /**
   * 响应 httpcode
   */
  public httpCode?: number;

  /**
   * 相应头
   */
  public headers?: Record<string, string>;

  public accessUrl?:string;
  parseResponseBody(httpCode: number, headers: Record<string, string>, arrayBuffer: ArrayBuffer){
    this.httpCode = httpCode;
    this.headers = headers;
    this.contentParser(arrayBuffer);
  }

  /**
   * 重写该方法解析具体的内容类
   */
  contentParser(arrayBuffer: ArrayBuffer){

  }
}