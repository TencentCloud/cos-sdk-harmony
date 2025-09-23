import { rcp } from '@kit.RemoteCommunicationKit';

export class QCloudRequestData extends Object{
  public taskId:number = 0;
  public url?:rcp.URLOrString;
  public method?: rcp.HttpMethod
  public headers?: rcp.RequestHeaders
  public content?: rcp.RequestContent
  public cookies?: rcp.RequestCookies
  public transferRange?: rcp.TransferRange | rcp.TransferRange[]
  public requestConfiguration?: rcp.Configuration
  public progressGranularity?: number
}