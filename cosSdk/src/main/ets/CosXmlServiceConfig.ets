import { rcp } from "@kit.RemoteCommunicationKit";
import { NetworkClient } from "@tencentcloud/foundation";
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
   *
   * 若设置了 requestConfiguration，则该参数不生效。需要在 requestConfiguration 中设置。
   * 具体请参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/remote-communication-rcp-V5#section1898141153617
   */
  readTimeout: number = 30 * 1000;

  /**
   * 连接超时时间。单位为毫秒（ms），默认为15 * 1000ms。
   *
   * 若设置了 requestConfiguration，则该参数不生效。需要在 requestConfiguration 中设置。
   * 具体请参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/remote-communication-rcp-V5#section1898141153617
   */
  connectTimeout: number = 15 * 1000;

  /**
   * 设置DNS配置
   *
   * 若设置了 requestConfiguration，则该参数不生效。需要在 requestConfiguration 中设置。
   * 具体请参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp#section9677185417382
   */
  dnsConfiguration?: rcp.DnsConfiguration;

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

  /**
   * 单次网络请求的进度回调的时间颗粒度，默认为500ms
   * 主要用于进度回调的频控，防止频率过高导致的anr等问题
   */
  progressGranularity: number = 500;

  disableBackupHost:boolean = false;

  /**
   * 自定义网络层。
   *
   * 不设置时（默认），SDK 使用基于 HarmonyOS RemoteCommunicationKit（rcp）的默认网络实现，
   * 行为与旧版本完全一致，老客户无需任何改动。
   *
   * 如需接管网络通信（使用自研网络库、DNS 优化、弱网优化等），可继承 NetworkClient 并在此设置。
   * 详见 NetworkClient / NetworkProxy。
   *
   *   let config = new CosXmlServiceConfig("ap-guangzhou");
   *   config.networkClient = new MyNetworkClient();
   */
  networkClient?: NetworkClient;

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