import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import {
  CosXmlBaseService, CosXmlServiceConfig,
} from '../../../../Index';
import { GetObjectRequest } from '../../../main/ets/model/object/GetObjectRequest';
import { Credential } from './common/Credential';
import { Logger } from './common/Logger';
import { TestUtils } from './common/TestUtils';
import { rcp } from '@kit.RemoteCommunicationKit';

// Mock 服务器配置
const HOST_MYQCLOUD = "cos-sdk-err-retry-1253960454.cos.ap-chengdu.myqcloud.com";
const HOST_TENCENTCOS = "cos-sdk-err-retry-1253960454.cos.ap-chengdu.tencentcos.cn";
// jordanqin的外网轻量服务器IP
const MOCK_IP = "49.232.13.225";
const MOCK_PORT = 8080;
const RETRY_BUCKET = "cos-sdk-err-retry-1253960454";

/**
 * 创建 myqcloud 域名配置的 service
 * @param enableSwitch 是否支持域名切换
 */
function createServiceMyqcloud(enableSwitch: boolean): CosXmlBaseService {
  let config = new CosXmlServiceConfig("ap-chengdu");
  config.protocol = "http";
  config.port = MOCK_PORT;
  config.host = "${bucket}.cos.${region}.myqcloud.com";
  config.connectTimeout = 1000;
  config.readTimeout = 1000;
  const staticDnsRules: rcp.StaticDnsRules = [
    { host: HOST_MYQCLOUD, port: MOCK_PORT, ipAddresses: [MOCK_IP] },
    { host: HOST_TENCENTCOS, port: MOCK_PORT, ipAddresses: [MOCK_IP] }
  ];
  config.dnsConfiguration = { dnsRules: staticDnsRules };
  config.disableBackupHost = !enableSwitch;
  config.maxRetryCount = 3;
  config.retrySleep = 100; // 测试时缩短重试间隔
  return new CosXmlBaseService(
    TestUtils.getContext(),
    config,
    Credential.constCredential
  );
}

/**
 * 创建 tencentcos 域名配置的 service
 * @param enableSwitch 是否支持域名切换
 */
function createServiceTencentCos(enableSwitch: boolean): CosXmlBaseService {
  let config = new CosXmlServiceConfig("ap-chengdu");
  config.protocol = "http";
  config.port = MOCK_PORT;
  config.host = "${bucket}.cos.${region}.tencentcos.cn";
  config.connectTimeout = 1000;
  config.readTimeout = 1000;
  const staticDnsRules: rcp.StaticDnsRules = [
    { host: HOST_MYQCLOUD, port: MOCK_PORT, ipAddresses: [MOCK_IP] },
    { host: HOST_TENCENTCOS, port: MOCK_PORT, ipAddresses: [MOCK_IP] }
  ];
  config.dnsConfiguration = { dnsRules: staticDnsRules };
  config.disableBackupHost = !enableSwitch;
  config.maxRetryCount = 3;
  config.retrySleep = 100; // 测试时缩短重试间隔
  return new CosXmlBaseService(
    TestUtils.getContext(),
    config,
    Credential.constCredential
  );
}

/**
 * 执行 getObject 请求并验证结果
 * @param service COS服务实例
 * @param cosKey 对象key（用于触发不同的mock响应）
 * @param expectedHost 期望的最终请求host
 * @param expectedRetryCount 期望的重试次数
 */
async function getObjectAndVerify(
  service: CosXmlBaseService,
  cosKey: string,
  expectedHost: string,
  expectedRetryCount: number
): Promise<void> {
  let context = TestUtils.getContext();
  let filesDir = context.filesDir;
  let request = new GetObjectRequest(RETRY_BUCKET, cosKey, filesDir + '/' + cosKey);
  await TestUtils.requestAddCredential(request, service);

  try {
    let result = await service.getObject(request);
    // 成功时验证
    let actualRetryCount = request.httpTask?.getRetryCount() ?? 0;
    let actualUrl = request.httpTask?.getRequestUrl() ?? '';
    Logger.info(`[${cosKey}] Success - retryCount: ${actualRetryCount}, expectedRetryCount: ${expectedRetryCount}`);
    Logger.info(`[${cosKey}] Success - actualUrl: ${actualUrl}, expectedHost: ${expectedHost}`);

    expect(actualRetryCount).assertEqual(expectedRetryCount);
    expect(actualUrl.includes(expectedHost)).assertTrue();
  } catch (e) {
    // 失败时也要验证
    let actualRetryCount = request.httpTask?.getRetryCount() ?? 0;
    let actualUrl = request.httpTask?.getRequestUrl() ?? '';
    Logger.info(`[${cosKey}] Error - retryCount: ${actualRetryCount}, expectedRetryCount: ${expectedRetryCount}`);
    Logger.info(`[${cosKey}] Error - actualUrl: ${actualUrl}, expectedHost: ${expectedHost}`);
    TestUtils.printError(e);

    expect(actualRetryCount).assertEqual(expectedRetryCount);
    expect(actualUrl.includes(expectedHost)).assertTrue();
  }
}

/**
 * 重试和域名切换测试
 * 参考 Java 版本的 RetryCosWebServerMockTest
 *
 * 测试规则：
 * 1、2XX、4XX：不重试，不切换域名
 * 2、3XX：如果满足域名切换条件则切换域名再次请求，不重试
 * 3、5XX和未收到回包（超时、连接重置等错误）：按照重试策略进行重试，最后一次重试时当满足域名切换条件时切换域名再次请求一次
 */
export default function cosRetryTest() {
  describe('cosRetryTest', () => {
    // 4 种 service 配置
    let serviceMyqcloud: CosXmlBaseService;          // myqcloud域名，支持切换
    let serviceTencentCos: CosXmlBaseService;        // tencentcos域名，支持切换
    let serviceMyqcloudNoSwitch: CosXmlBaseService;  // myqcloud域名，不支持切换
    let serviceTencentCosNoSwitch: CosXmlBaseService; // tencentcos域名，不支持切换

    beforeAll(() => {
      // 初始化 4 种 service
      serviceMyqcloud = createServiceMyqcloud(true);
      serviceTencentCos = createServiceTencentCos(true);
      serviceMyqcloudNoSwitch = createServiceMyqcloud(false);
      serviceTencentCosNoSwitch = createServiceTencentCos(false);
    })

    beforeEach(() => {
    })

    afterEach(() => {
    })

    afterAll(() => {
    })

    // ==================== 2XX 测试（不重试，不切换域名）====================

    it('noSwitch_200', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "200", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "200", HOST_TENCENTCOS, 0);
      done();
    })

    it('switch_200', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "200", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCos, "200", HOST_TENCENTCOS, 0);
      done();
    })

    it('noSwitch_200r', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "200r", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "200r", HOST_TENCENTCOS, 0);
      done();
    })

    it('switch_200r', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "200r", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCos, "200r", HOST_TENCENTCOS, 0);
      done();
    })

    it('noSwitch_204', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "204", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "204", HOST_TENCENTCOS, 0);
      done();
    })

    it('switch_204', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "204", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCos, "204", HOST_TENCENTCOS, 0);
      done();
    })

    it('noSwitch_206', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "206", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "206", HOST_TENCENTCOS, 0);
      done();
    })

    it('switch_206', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "206", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCos, "206", HOST_TENCENTCOS, 0);
      done();
    })

    // ==================== 3XX 测试（不重试，满足条件时切换域名）====================
    // 3XX为直切域名试一次，不再重试（标记最大重试次数，避免再次重试），因此这里为3（最大重试次数）+1（切域名重试的一次） 或者 3（最大重试次数）
    it('noSwitch_301', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "301", HOST_MYQCLOUD, 3);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "301", HOST_TENCENTCOS, 3);
      done();
    })

    it('switch_301', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "301", HOST_TENCENTCOS, 4);
      await getObjectAndVerify(serviceTencentCos, "301", HOST_TENCENTCOS, 3);
      done();
    })

    it('noSwitch_301r', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "301r", HOST_MYQCLOUD, 3);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "301r", HOST_TENCENTCOS, 3);
      done();
    })

    it('switch_301r', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "301r", HOST_MYQCLOUD, 3);
      await getObjectAndVerify(serviceTencentCos, "301r", HOST_TENCENTCOS, 3);
      done();
    })

    it('noSwitch_302', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "302", HOST_MYQCLOUD, 3);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "302", HOST_TENCENTCOS, 3);
      done();
    })

    it('switch_302', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "302", HOST_TENCENTCOS, 4);
      await getObjectAndVerify(serviceTencentCos, "302", HOST_TENCENTCOS, 3);
      done();
    })

    it('noSwitch_302r', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "302r", HOST_MYQCLOUD, 3);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "302r", HOST_TENCENTCOS, 3);
      done();
    })

    it('switch_302r', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "302r", HOST_MYQCLOUD, 3);
      await getObjectAndVerify(serviceTencentCos, "302r", HOST_TENCENTCOS, 3);
      done();
    })

    // ==================== 4XX 测试（不重试，不切换域名）====================

    it('noSwitch_400', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "400", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "400", HOST_TENCENTCOS, 0);
      done();
    })

    it('switch_400', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "400", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCos, "400", HOST_TENCENTCOS, 0);
      done();
    })

    it('noSwitch_400r', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "400r", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "400r", HOST_TENCENTCOS, 0);
      done();
    })

    it('switch_400r', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "400r", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCos, "400r", HOST_TENCENTCOS, 0);
      done();
    })

    it('noSwitch_403', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "403", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "403", HOST_TENCENTCOS, 0);
      done();
    })

    it('switch_403', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "403", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCos, "403", HOST_TENCENTCOS, 0);
      done();
    })

    it('noSwitch_403r', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "403r", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "403r", HOST_TENCENTCOS, 0);
      done();
    })

    it('switch_403r', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "403r", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCos, "403r", HOST_TENCENTCOS, 0);
      done();
    })

    it('noSwitch_404', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "404", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "404", HOST_TENCENTCOS, 0);
      done();
    })

    it('switch_404', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "404", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCos, "404", HOST_TENCENTCOS, 0);
      done();
    })

    it('noSwitch_404r', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "404r", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "404r", HOST_TENCENTCOS, 0);
      done();
    })

    it('switch_404r', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "404r", HOST_MYQCLOUD, 0);
      await getObjectAndVerify(serviceTencentCos, "404r", HOST_TENCENTCOS, 0);
      done();
    })

    // ==================== 5XX 测试（重试，最后一次重试时满足条件则切换域名）====================

    it('noSwitch_500', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "500", HOST_MYQCLOUD, 3);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "500", HOST_TENCENTCOS, 3);
      done();
    })

    it('switch_500', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "500", HOST_TENCENTCOS, 3);
      await getObjectAndVerify(serviceTencentCos, "500", HOST_TENCENTCOS, 3);
      done();
    })

    it('noSwitch_500r', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "500r", HOST_MYQCLOUD, 3);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "500r", HOST_TENCENTCOS, 3);
      done();
    })

    it('switch_500r', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "500r", HOST_MYQCLOUD, 3);
      await getObjectAndVerify(serviceTencentCos, "500r", HOST_TENCENTCOS, 3);
      done();
    })

    it('noSwitch_503', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "503", HOST_MYQCLOUD, 3);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "503", HOST_TENCENTCOS, 3);
      done();
    })

    it('switch_503', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "503", HOST_TENCENTCOS, 3);
      await getObjectAndVerify(serviceTencentCos, "503", HOST_TENCENTCOS, 3);
      done();
    })

    it('noSwitch_503r', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "503r", HOST_MYQCLOUD, 3);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "503r", HOST_TENCENTCOS, 3);
      done();
    })

    it('switch_503r', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "503r", HOST_MYQCLOUD, 3);
      await getObjectAndVerify(serviceTencentCos, "503r", HOST_TENCENTCOS, 3);
      done();
    })

    it('noSwitch_504', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "504", HOST_MYQCLOUD, 3);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "504", HOST_TENCENTCOS, 3);
      done();
    })

    it('switch_504', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "504", HOST_TENCENTCOS, 3);
      await getObjectAndVerify(serviceTencentCos, "504", HOST_TENCENTCOS, 3);
      done();
    })

    it('noSwitch_504r', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "504r", HOST_MYQCLOUD, 3);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "504r", HOST_TENCENTCOS, 3);
      done();
    })

    it('switch_504r', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "504r", HOST_MYQCLOUD, 3);
      await getObjectAndVerify(serviceTencentCos, "504r", HOST_TENCENTCOS, 3);
      done();
    })

    // ==================== 网络错误测试（重试，最后一次重试时满足条件则切换域名）====================

    it('noSwitch_timeout', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "timeout", HOST_MYQCLOUD, 3);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "timeout", HOST_TENCENTCOS, 3);
      done();
    })

    it('switch_timeout', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "timeout", HOST_TENCENTCOS, 3);
      await getObjectAndVerify(serviceTencentCos, "timeout", HOST_TENCENTCOS, 3);
      done();
    })

    it('noSwitch_shutdown', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloudNoSwitch, "shutdown", HOST_MYQCLOUD, 3);
      await getObjectAndVerify(serviceTencentCosNoSwitch, "shutdown", HOST_TENCENTCOS, 3);
      done();
    })

    it('switch_shutdown', 0, async (done: Function) => {
      await getObjectAndVerify(serviceMyqcloud, "shutdown", HOST_TENCENTCOS, 3);
      await getObjectAndVerify(serviceTencentCos, "shutdown", HOST_TENCENTCOS, 3);
      done();
    })
  })
}