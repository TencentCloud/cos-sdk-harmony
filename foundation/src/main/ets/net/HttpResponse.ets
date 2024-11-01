// http响应
export class HttpResponse<T>{
  public httpCode?:number;
  public headers?:Record<string, string>;
  public content?: T;

}