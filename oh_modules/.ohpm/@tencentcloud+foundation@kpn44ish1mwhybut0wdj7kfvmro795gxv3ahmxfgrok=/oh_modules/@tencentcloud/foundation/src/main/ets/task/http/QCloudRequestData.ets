import { http } from '@kit.NetworkKit';

export class QCloudRequestData extends Object{
  public taskId:number = 0;
  public url?:string;
  public httpRequestOptions?:http.HttpRequestOptions;
}