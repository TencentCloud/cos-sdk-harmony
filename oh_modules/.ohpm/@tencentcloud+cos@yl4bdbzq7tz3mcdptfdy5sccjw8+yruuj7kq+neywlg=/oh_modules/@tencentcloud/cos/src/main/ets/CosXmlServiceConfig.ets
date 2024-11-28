import { rcp } from "@kit.RemoteCommunicationKit";
import { CosInvalidArgumentError } from "./error/CosInvalidArgumentError";

export class CosXmlServiceConfig {

  /**
   * 请求使用的协议，支持 http/https;
   */
  protocol: string = "https";

  /**
   * 自定义域名
   * ${bucket} 存储桶占位符
   * ${region} 地域参数占位符
   */
  host: string = "${bucket}.cos.${region}.myqcloud.com";

  /**
   * 端口号。
   */
  port: number = -1;

  /**
   * 读取超时时间。单位为毫秒（ms），默认为30 * 1000ms。
   * 设置为0表示不会出现超时情况。
   */
  readTimeout: number = 30 * 1000;

  /**
   * 连接超时时间。单位为毫秒（ms），默认为15 * 1000ms。
   */
  connectTimeout: number = 15 * 1000;

  /**
   * 设置使用https协议的服务器进行DNS解析。
   * 参数必须以以下格式进行URL编码："https:// host:port/path"。
   */
  dnsOverHttps: string | undefined;
  /**
   * 设置指定的DNS服务器进行DNS解析。
   * -可以设置多个DNS解析服务器，最多3个服务器。如果有3个以上，只取前3个。
   * -服务器必须是IPV4或者IPV6地址。
   */
  dnsServers: Array<string> | undefined;

  /**
   * 网络高级配置
   * 具体请参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/remote-communication-rcp-V5#section1898141153617
   */
  requestConfiguration?: rcp.Configuration;
  /**
   * 设置公共header
   */
  headers: Map<string, string> = new Map();

  /**
   * 指定header 不参与签名
   */
  noSignHeaderKeys: Set<string> = new Set();

  /**
   * 上传任务并发数。
   */
  uploadMaxConcurrentCount: number = 4;

  /**
   * 下载任务并发数。
   */
  downloadMaxConcurrentCount: number = 4;

  /**
   * 重试策略
   * 重试最大次数，单位：次；
   * 默认3次。
   */
  maxRetryCount:number = 3;

  /**
   * 重试策略
   * 重试间隔时间，单位：ms；
   * 默认间隔1s
   */
  retrySleep:number = 1 * 1000;

  /**
   * 请求 host 中${region}参数
   * 推荐，一个地域注册一个service.
   */
  region: string|undefined;

  constructor(region?: string) {
    this.region = region;
  }

  getRequestHost(bucket: string|undefined, region: string|undefined): string {
    let finalRegion = region;
    if(!finalRegion){
      finalRegion = this.region;
    }

    if(!finalRegion){
      return this.host;
    } else {
      if(bucket){
        const regex = /^[a-zA-Z0-9.-]*$/;
        if (!regex.test(bucket)) {
          throw new CosInvalidArgumentError('bucket contains illegal character! It can only contains a-z, A-Z, 0-9, . and -');
        }
        if (!regex.test(finalRegion)) {
          throw new CosInvalidArgumentError('region contains illegal character! It can only contains a-z, A-Z, 0-9, . and -');
        }
        return this.host.replace("${bucket}", bucket).replace("${region}", finalRegion);
      } else {
        return "service.cos.myqcloud.com";
      }
    }
  }
}