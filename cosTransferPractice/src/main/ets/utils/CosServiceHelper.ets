import { CosXmlBaseService, CosXmlServiceConfig } from '@tencentcloud/cos';
import { Credential } from '../Credential';
import { Const, CredentialType } from '../Const';
import { OhHttpNetworkClient } from '../example/CustomNetworkExample';

/**
 * COS 服务初始化助手：支持在「默认网络层(rcp)」与「自定义网络层(@ohos.net.http)」之间切换。
 *
 * 开关状态保存在 AppStorage['useCustomNetwork'] 中，页面通过 @StorageLink 绑定；
 * 切换时重新初始化默认服务（CosXmlBaseService.default()），后续请求即走新的网络层。
 */
export class CosServiceHelper {
  static readonly STORAGE_KEY: string = 'useCustomNetwork';

  /** 读取当前开关（默认关闭，即使用默认 rcp 网络层） */
  static isUseCustomNetwork(): boolean {
    return AppStorage.get<boolean>(CosServiceHelper.STORAGE_KEY) ?? false;
  }

  /**
   * 按开关重新初始化默认 COS 服务。
   * @param context 应用上下文
   * @param useCustomNetwork true=自定义网络层(@ohos.net.http)，false=默认网络层(rcp)
   */
  static initDefaultService(context: Context, useCustomNetwork: boolean): void {
    AppStorage.setOrCreate(CosServiceHelper.STORAGE_KEY, useCustomNetwork);

    let config = new CosXmlServiceConfig(Const.TEST_BUCKET_REGION);
    config.retrySleep = 5 * 1000;
    // config.readTimeout = 30 * 1000 * 1000;
    // 关键：打开开关时注入自定义网络层；关闭时不设置，走默认 rcp 实现
    if (useCustomNetwork) {
      config.networkClient = new OhHttpNetworkClient();
    }

    // const customDnsServers: rcp.DnsServers = [
    //   { ip: "8.8.8.8" },
    //   { ip: "8.8.4.4", port: 53 }
    // ];
    // config.dnsConfiguration = {dnsRules:customDnsServers};

    // QCloudLogger.logOutputCallback = (log)=>{
    //   console.log("logOutputCallback" + log);
    // }

    if (Const.CREDENTIAL_TYPE === CredentialType.STS) {
      CosXmlBaseService.initDefaultService(context, config, Credential.sessionCredential);
    } else if (Const.CREDENTIAL_TYPE === CredentialType.CONST) {
      CosXmlBaseService.initDefaultService(context, config, Credential.constCredential);
    } else {
      CosXmlBaseService.initDefaultService(context, config);
    }
  }
}
