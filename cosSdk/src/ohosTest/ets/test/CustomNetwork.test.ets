import { describe, beforeAll, it, expect } from '@ohos/hypium';
import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';
import {
  CosXmlBaseService,
  CosXmlServiceConfig,
  PutObjectRequest,
  GetObjectRequest,
  GetObjectArrayBufferRequest,
  HeadObjectRequest,
  HeadObjectResult,
  UploadTask,
  NetworkClient,
  NetworkProxy,
  NetworkClientConfig,
  CustomNetworkRequest,
  CustomNetworkResponseHandler,
  CosError,
  CosErrorCode
} from '../../../../Index';
import { Credential } from './common/Credential';
import { Logger } from './common/Logger';
import { TestConst } from './common/TestConst';
import { TestUtils } from './common/TestUtils';
import { FileUtils } from './common/FileUtils';
import { CRC64 } from './common/CRC64';

/**
 * 基于 @ohos.net.http 的自定义网络执行代理（示例实现，用于验证自定义网络层）。
 * 使用 requestInStream 流式接收响应；等状态码与 dataEnd 都到达后再 onComplete。
 */
class TestHttpNetworkProxy extends NetworkProxy {
  private httpRequest?: http.HttpRequest;
  private statusCode?: number;
  private dataEnded: boolean = false;
  private terminated: boolean = false;
  private handler?: CustomNetworkResponseHandler;

  executeHttpRequest(request: CustomNetworkRequest, handler: CustomNetworkResponseHandler): void {
    this.handler = handler;
    this.httpRequest = http.createHttp();

    this.httpRequest.on('headersReceive', (headers: Object) => {
      handler.onResponseHeaders(headers as Record<string, string>);
    });
    this.httpRequest.on('dataReceive', (chunk: ArrayBuffer) => {
      handler.onData(chunk);
    });
    this.httpRequest.on('dataEnd', () => {
      this.dataEnded = true;
      this.tryComplete();
    });
    this.httpRequest.on('dataSendProgress', (info: http.DataSendProgressInfo) => {
      handler.onProgress(info.sendSize, info.totalSize);
    });
    this.httpRequest.on('dataReceiveProgress', (info: http.DataReceiveProgressInfo) => {
      handler.onProgress(info.receiveSize, info.totalSize);
    });

    let options: http.HttpRequestOptions = {
      method: request.method as http.RequestMethod,
      header: request.headers,
      extraData: request.body,
      connectTimeout: request.connectTimeoutMs,
      readTimeout: request.readTimeoutMs
    };

    this.httpRequest.requestInStream(request.url, options,
      (err: BusinessError, statusCode: number) => {
        if (err) {
          this.fail(err);
          return;
        }
        this.statusCode = statusCode;
        this.tryComplete();
      });
  }

  cancel(): void {
    if (this.terminated) {
      return;
    }
    this.terminated = true;
    this.cleanup();
  }

  private tryComplete(): void {
    if (this.terminated || this.statusCode === undefined || !this.dataEnded) {
      return;
    }
    this.terminated = true;
    this.handler?.onComplete(this.statusCode);
    this.cleanup();
  }

  private fail(error: Error): void {
    if (this.terminated) {
      return;
    }
    this.terminated = true;
    this.handler?.onFailure(error);
    this.cleanup();
  }

  private cleanup(): void {
    if (this.httpRequest) {
      this.httpRequest.off('headersReceive');
      this.httpRequest.off('dataReceive');
      this.httpRequest.off('dataEnd');
      this.httpRequest.off('dataSendProgress');
      this.httpRequest.off('dataReceiveProgress');
      this.httpRequest.destroy();
      this.httpRequest = undefined;
    }
  }
}

/**
 * 基于 @ohos.net.http 的自定义网络客户端（示例实现）。
 */
class TestHttpNetworkClient extends NetworkClient {
  getNetworkProxy(): NetworkProxy {
    return new TestHttpNetworkProxy();
  }
}

// ===== 重试测试用 mock 服务器配置（与 CosRetry.test 一致）=====
const HOST_MYQCLOUD = 'cos-sdk-err-retry-1253960454.cos.ap-chengdu.myqcloud.com';
const HOST_TENCENTCOS = 'cos-sdk-err-retry-1253960454.cos.ap-chengdu.tencentcos.cn';
const MOCK_IP = '49.232.13.225';
const MOCK_PORT = 8080;
const RETRY_BUCKET = 'cos-sdk-err-retry-1253960454';

/**
 * 重试测试用自定义网络代理：在自定义网络层内把 COS 域名重写为 mock 服务器 IP
 * （因为自定义实现不使用 rcp 的 dnsConfiguration，故在此手动路由到 mock）。
 * SDK 侧的请求 URL 仍是 COS 域名，不影响域名切换判定与 getRequestUrl 断言。
 */
class MockRewriteNetworkProxy extends NetworkProxy {
  private httpRequest?: http.HttpRequest;
  private statusCode?: number;
  private dataEnded: boolean = false;
  private terminated: boolean = false;
  private handler?: CustomNetworkResponseHandler;

  executeHttpRequest(request: CustomNetworkRequest, handler: CustomNetworkResponseHandler): void {
    this.handler = handler;
    this.httpRequest = http.createHttp();
    this.httpRequest.on('headersReceive', (headers: Object) => {
      handler.onResponseHeaders(headers as Record<string, string>);
    });
    this.httpRequest.on('dataReceive', (chunk: ArrayBuffer) => {
      handler.onData(chunk);
    });
    this.httpRequest.on('dataEnd', () => {
      this.dataEnded = true;
      this.tryComplete();
    });

    // 把 COS 域名重写为 mock 服务器 IP
    let url = request.url.replace(HOST_MYQCLOUD, MOCK_IP).replace(HOST_TENCENTCOS, MOCK_IP);

    let options: http.HttpRequestOptions = {
      method: request.method as http.RequestMethod,
      header: request.headers,
      extraData: request.body,
      connectTimeout: request.connectTimeoutMs,
      readTimeout: request.readTimeoutMs
    };
    this.httpRequest.requestInStream(url, options, (err: BusinessError, statusCode: number) => {
      if (err) {
        this.fail(err);
        return;
      }
      this.statusCode = statusCode;
      this.tryComplete();
    });
  }

  cancel(): void {
    if (this.terminated) {
      return;
    }
    this.terminated = true;
    this.cleanup();
  }

  private tryComplete(): void {
    if (this.terminated || this.statusCode === undefined || !this.dataEnded) {
      return;
    }
    this.terminated = true;
    this.handler?.onComplete(this.statusCode);
    this.cleanup();
  }

  private fail(error: Error): void {
    if (this.terminated) {
      return;
    }
    this.terminated = true;
    this.handler?.onFailure(error);
    this.cleanup();
  }

  private cleanup(): void {
    if (this.httpRequest) {
      this.httpRequest.off('headersReceive');
      this.httpRequest.off('dataReceive');
      this.httpRequest.off('dataEnd');
      this.httpRequest.destroy();
      this.httpRequest = undefined;
    }
  }
}

class MockRewriteNetworkClient extends NetworkClient {
  getNetworkProxy(): NetworkProxy {
    return new MockRewriteNetworkProxy();
  }
}

function createMockRewriteService(enableSwitch: boolean): CosXmlBaseService {
  let config = new CosXmlServiceConfig('ap-chengdu');
  config.protocol = 'http';
  config.port = MOCK_PORT;
  config.host = '${bucket}.cos.${region}.myqcloud.com';
  config.connectTimeout = 1000;
  config.readTimeout = 1000;
  config.disableBackupHost = !enableSwitch;
  config.maxRetryCount = 3;
  config.retrySleep = 100;
  // 关键：注入自定义网络层
  config.networkClient = new MockRewriteNetworkClient();
  return new CosXmlBaseService(TestUtils.getContext(), config, Credential.constCredential);
}

async function getObjectAndVerifyRetry(service: CosXmlBaseService, cosKey: string,
  expectedHost: string, expectedRetryCount: number, expectSuccess: boolean): Promise<void> {
  let filesDir = TestUtils.getContext().filesDir;
  let request = new GetObjectRequest(RETRY_BUCKET, cosKey, filesDir + '/retry_' + cosKey);
  let succeeded = false;
  let statusCode = 0;
  try {
    let result = await service.getObject(request);
    succeeded = true;
    statusCode = result.httpCode ?? 0;
  } catch (e) {
    TestUtils.printError(e as CosError);
  }
  let actualRetryCount = request.httpTask?.getRetryCount() ?? 0;
  let actualUrl = request.httpTask?.getRequestUrl() ?? '';
  Logger.info(`[custom-retry ${cosKey}] success=${succeeded} code=${statusCode} retryCount=${actualRetryCount}/${expectedRetryCount} url=${actualUrl}`);
  // 明确断言结果，避免请求异常时仅凭重试次数误判通过：
  // - 期望成功：必须成功且为 2xx；
  // - 期望非成功：要么失败，要么以非 2xx 状态码返回（不能意外地以 2xx 成功）。
  if (expectSuccess) {
    expect(succeeded).assertTrue();
    expect(statusCode >= 200 && statusCode < 300).assertTrue();
  } else {
    let non2xx = statusCode < 200 || statusCode >= 300;
    expect(!succeeded || non2xx).assertTrue();
  }
  expect(actualRetryCount).assertEqual(expectedRetryCount);
  expect(actualUrl.includes(expectedHost)).assertTrue();
}

// ===== 确定性 Fake 网络代理（不访问网络，用于验证网络层协议）=====
type FakeBehavior = (request: CustomNetworkRequest, handler: CustomNetworkResponseHandler,
  proxy: FakeNetworkProxy) => void;

class FakeNetworkProxy extends NetworkProxy {
  behavior: FakeBehavior;
  onCancel?: () => void;

  constructor(behavior: FakeBehavior) {
    super();
    this.behavior = behavior;
  }

  executeHttpRequest(request: CustomNetworkRequest, handler: CustomNetworkResponseHandler): void {
    this.behavior(request, handler, this);
  }

  cancel(): void {
    if (this.onCancel) {
      this.onCancel();
    }
  }
}

class FakeNetworkClient extends NetworkClient {
  behaviorFactory: () => FakeBehavior;
  proxies: FakeNetworkProxy[] = [];
  initCount: number = 0;

  constructor(behaviorFactory: () => FakeBehavior) {
    super();
    this.behaviorFactory = behaviorFactory;
  }

  init(config: NetworkClientConfig): void {
    super.init(config);
    this.initCount++;
  }

  getNetworkProxy(): NetworkProxy {
    let proxy = new FakeNetworkProxy(this.behaviorFactory());
    this.proxies.push(proxy);
    return proxy;
  }
}

function fakeService(client: FakeNetworkClient, maxRetry: number): CosXmlBaseService {
  let config = new CosXmlServiceConfig(TestConst.PERSIST_BUCKET_REGION);
  config.networkClient = client;
  config.maxRetryCount = maxRetry;
  config.retrySleep = 10;
  return new CosXmlBaseService(TestUtils.getContext(), config, Credential.constCredential);
}

/**
 * 自定义网络层测试：验证通过自定义网络层（@ohos.net.http）时，
 * 签名、请求、响应转换、进度、取消、错误透传等能力仍然正常工作。
 */
export default function customNetworkTest() {
  describe('customNetworkTest', () => {
    let service: CosXmlBaseService;

    beforeAll(() => {
      let config = new CosXmlServiceConfig(TestConst.PERSIST_BUCKET_REGION);
      // 关键：注入自定义网络层
      config.networkClient = new TestHttpNetworkClient();
      service = new CosXmlBaseService(TestUtils.getContext(), config, Credential.constCredential);
    })

    it('customNetwork_headObject', 0, async (done: Function) => {
      let request = new HeadObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_PATH);
      try {
        let result = await service.headObject(request);
        Logger.info(result);
        if (result.eTag()) {
          expect(true).assertTrue();
        } else {
          expect().assertFail();
        }
      } catch (e) {
        TestUtils.printError(e as CosError);
        expect().assertFail();
      }
      done();
    })

    it('customNetwork_getObjectToArrayBuffer', 0, async (done: Function) => {
      let request = new GetObjectArrayBufferRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_PATH);
      try {
        let result = await service.getObjectToArrayBuffer(request);
        if (result && result.byteLength > 0) {
          Logger.info(result.byteLength.toString());
          expect(true).assertTrue();
        } else {
          expect().assertFail();
        }
      } catch (e) {
        TestUtils.printError(e as CosError);
        expect().assertFail();
      }
      done();
    })

    it('customNetwork_getObjectToFile', 0, async (done: Function) => {
      let filesDir = TestUtils.getContext().filesDir;
      let request = new GetObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_PATH,
        filesDir + '/custom_net_test.jpg');
      try {
        let result = await service.getObject(request);
        if (result.httpCode && result.httpCode >= 200 && result.httpCode < 300) {
          expect(true).assertTrue();
        } else {
          expect().assertFail();
        }
      } catch (e) {
        TestUtils.printError(e as CosError);
        expect().assertFail();
      }
      done();
    })

    it('customNetwork_putObject_withProgress', 0, async (done: Function) => {
      // 用内存 buffer 上传，验证请求体透传与上传进度回调
      let body = new ArrayBuffer(64 * 1024);
      let request = new PutObjectRequest(TestConst.PERSIST_BUCKET, 'do_not_remove/custom_net_put.bin', body);
      let progressCalled = false;
      request.onProgress = (progress) => {
        if (progress.complete > 0 && progress.target > 0) {
          progressCalled = true;
        }
      };
      try {
        let result = await service.putObject(request);
        if (result.httpCode && result.httpCode >= 200 && result.httpCode < 300) {
          expect(progressCalled).assertTrue();
        } else {
          expect().assertFail();
        }
      } catch (e) {
        TestUtils.printError(e as CosError);
        expect().assertFail();
      }
      done();
    })

    it('customNetwork_getObjectCancel', 0, async (done: Function) => {
      let filesDir = TestUtils.getContext().filesDir;
      let request = new GetObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_6M_PATH,
        filesDir + '/custom_net_cancel.jpg');
      request.onProgress = (progress) => {
        if (progress.target > 0 && progress.complete / progress.target > 0.2) {
          service.cancel(request);
        }
      };
      try {
        await service.getObject(request);
        expect().assertFail();
      } catch (e) {
        if ((e as CosError).cosErrorCode === CosErrorCode.USER_CANCELLED) {
          expect(true).assertTrue();
        } else {
          TestUtils.printError(e as CosError);
          expect().assertFail();
        }
      }
      done();
    })

    it('customNetwork_error_notExistObject', 0, async (done: Function) => {
      // 请求不存在的对象，验证服务端错误能正常透传
      let request = new HeadObjectRequest(TestConst.PERSIST_BUCKET, 'do_not_remove/not_exist_object_xxx');
      try {
        await service.headObject(request);
        expect().assertFail();
      } catch (e) {
        // 期望拿到错误（4XX），说明错误链路正常
        Logger.info((e as CosError).message);
        expect(true).assertTrue();
      }
      done();
    })

    // 分片上传 + 下载回来 + CRC64 校验：验证自定义网络层的请求体透传、分片上传(init/part/complete)、
    // 多分片流式下载与数据完整性
    it('customNetwork_multipartUpload_downloadBack_integrity', 0, async (done: Function) => {
      let filesDir = TestUtils.getContext().filesDir;
      // 2MB > simpleUploadLimit(1MB)，触发分片上传（2 个分片）
      let srcPath = FileUtils.getFile(2 * 1024 * 1024, 'customNetMultipartSrc');
      let cosKey = 'do_not_remove/custom_net_multipart.bin';
      let downloadPath = filesDir + '/custom_net_multipart_back.bin';

      let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, cosKey, srcPath);
      let uploadTask: UploadTask = service.upload(putRequest);
      uploadTask.onResult = {
        onSuccess: async (req, result) => {
          try {
            // 下载回来
            let getRequest = new GetObjectRequest(TestConst.PERSIST_BUCKET, cosKey, downloadPath);
            let dl = await service.getObject(getRequest);
            if (!(dl.httpCode && dl.httpCode >= 200 && dl.httpCode < 300)) {
              expect().assertFail();
              done();
              return;
            }
            // CRC64 对比上传源文件与下载文件，验证数据完整性
            let srcCrc = await CRC64.crc64File(srcPath);
            let downCrc = await CRC64.crc64File(downloadPath);
            Logger.info(`integrity srcCrc=${srcCrc} downCrc=${downCrc}`);
            expect(srcCrc === downCrc).assertTrue();
          } catch (e) {
            TestUtils.printError(e as CosError);
            expect().assertFail();
          }
          done();
        },
        onFail: (req, error) => {
          TestUtils.printError(error);
          expect().assertFail();
          done();
        }
      };
      uploadTask.start();
    })

    // 并发请求：同时发起多个请求，验证 taskId 事件隔离（互不串扰）
    it('customNetwork_concurrentRequests', 0, async (done: Function) => {
      let requests: Promise<HeadObjectResult>[] = [];
      for (let i = 0; i < 5; i++) {
        requests.push(service.headObject(new HeadObjectRequest(TestConst.PERSIST_BUCKET,
          TestConst.PERSIST_BUCKET_PIC_PATH)));
      }
      try {
        let results = await Promise.all(requests);
        let allOk = results.every((r) => r.eTag() !== undefined && r.eTag()!.length > 0);
        expect(allOk).assertTrue();
      } catch (e) {
        TestUtils.printError(e as CosError);
        expect().assertFail();
      }
      done();
    })
  })

  // ==================== 自定义网络层 × 重试/域名切换 ====================
  // 通过 mock 服务器验证：自定义网络层下，SDK 的重试与域名切换逻辑仍然生效。
  // mock 服务器按对象 key 返回特定状态码（"500"→500，"timeout"→超时等）。
  describe('customNetworkRetryTest', () => {
    let serviceSwitch: CosXmlBaseService;      // myqcloud 域名，支持切换
    let serviceNoSwitch: CosXmlBaseService;    // myqcloud 域名，不支持切换

    beforeAll(() => {
      serviceSwitch = createMockRewriteService(true);
      serviceNoSwitch = createMockRewriteService(false);
    })

    it('customNetworkRetry_200_noRetry', 0, async (done: Function) => {
      await getObjectAndVerifyRetry(serviceSwitch, '200', HOST_MYQCLOUD, 0, true);
      done();
    })

    it('customNetworkRetry_404_noRetry', 0, async (done: Function) => {
      await getObjectAndVerifyRetry(serviceSwitch, '404', HOST_MYQCLOUD, 0, false);
      done();
    })

    it('customNetworkRetry_500_noSwitch', 0, async (done: Function) => {
      await getObjectAndVerifyRetry(serviceNoSwitch, '500', HOST_MYQCLOUD, 3, false);
      done();
    })

    it('customNetworkRetry_500_switch', 0, async (done: Function) => {
      // 5XX 重试到最后一次切换域名 → 最终 host 为 tencentcos
      await getObjectAndVerifyRetry(serviceSwitch, '500', HOST_TENCENTCOS, 3, false);
      done();
    })

    it('customNetworkRetry_timeout', 0, async (done: Function) => {
      // 网络错误（超时）按重试策略重试
      await getObjectAndVerifyRetry(serviceSwitch, 'timeout', HOST_TENCENTCOS, 3, false);
      done();
    })
  })

  // ==================== 确定性 Fake 网络层协议测试（不访问网络）====================
  // 用可控的 Fake 代理精确验证 SDK 与网络层的交互协议，不依赖真实网络/凭证服务/mock 服务器。
  describe('customNetworkFakeProxyTest', () => {

    it('fake_syncSuccess', 0, async (done: Function) => {
      // 同步回调完成：验证同步 success 不破坏任务状态（终态应为 Finish，非被覆盖回 Process）
      let client = new FakeNetworkClient(() => (req, h) => {
        h.onResponseHeaders({ 'content-type': 'application/octet-stream' });
        h.onData(new ArrayBuffer(16));
        h.onComplete(200);
      });
      let service = fakeService(client, 0);
      let request = new GetObjectArrayBufferRequest(TestConst.PERSIST_BUCKET, 'fake/syncSuccess');
      try {
        let result = await service.getObjectToArrayBuffer(request);
        // 完全同步回调（onResponseHeaders/onData/onComplete）仍能正确成功返回数据，
        // 证明「先置 Process 再启动网络」的重排下，同步终态不会破坏任务流程。
        expect(result?.byteLength).assertEqual(16);
        // NetworkClient 只初始化一次
        expect(client.initCount).assertEqual(1);
      } catch (e) {
        TestUtils.printError(e as CosError);
        expect().assertFail();
      }
      done();
    })

    it('fake_syncFailure', 0, async (done: Function) => {
      // 同步 onFailure：应失败（maxRetry=0 不重试），且归类为网络错误；不应挂起
      let client = new FakeNetworkClient(() => (req, h) => {
        h.onFailure(new Error('sync failure'));
      });
      let service = fakeService(client, 0);
      let failed = false;
      let errorCode: string | undefined;
      try {
        await service.getObjectToArrayBuffer(
          new GetObjectArrayBufferRequest(TestConst.PERSIST_BUCKET, 'fake/syncFailure'));
      } catch (e) {
        failed = true;
        errorCode = (e as CosError).cosErrorCode;
      }
      expect(failed).assertTrue();
      expect(errorCode).assertEqual(CosErrorCode.NETWORK);
      done();
    })

    it('fake_syncThrow', 0, async (done: Function) => {
      // executeHttpRequest 同步抛异常：应归类为任务错误并失败，不应挂起
      let client = new FakeNetworkClient(() => (req, h) => {
        throw new Error('sync throw');
      });
      let service = fakeService(client, 0);
      let failed = false;
      let errorCode: string | undefined;
      try {
        await service.getObjectToArrayBuffer(
          new GetObjectArrayBufferRequest(TestConst.PERSIST_BUCKET, 'fake/syncThrow'));
      } catch (e) {
        failed = true;
        errorCode = (e as CosError).cosErrorCode;
      }
      expect(failed).assertTrue();
      expect(errorCode).assertEqual(CosErrorCode.TASK);
      done();
    })

    it('fake_missingHeaderCompensation', 0, async (done: Function) => {
      // 自定义实现未调用 onResponseHeaders：SDK 应兜底补偿，任务仍能正常结束（不挂起）
      let client = new FakeNetworkClient(() => (req, h) => {
        h.onData(new ArrayBuffer(8));
        h.onComplete(200);
      });
      let service = fakeService(client, 0);
      try {
        let result = await service.getObjectToArrayBuffer(
          new GetObjectArrayBufferRequest(TestConst.PERSIST_BUCKET, 'fake/missingHeader'));
        expect(result?.byteLength).assertEqual(8);
      } catch (e) {
        TestUtils.printError(e as CosError);
        expect().assertFail();
      }
      done();
    })

    it('fake_duplicateCompleteIgnored', 0, async (done: Function) => {
      // 重复 onComplete、以及 complete 之后的 onFailure/onData 都应被忽略（只认第一次终态）
      let client = new FakeNetworkClient(() => (req, h) => {
        h.onResponseHeaders({});
        h.onData(new ArrayBuffer(4));
        h.onComplete(200);
        h.onComplete(500);
        h.onFailure(new Error('late failure'));
        h.onData(new ArrayBuffer(4));
      });
      let service = fakeService(client, 0);
      try {
        let result = await service.getObjectToArrayBuffer(
          new GetObjectArrayBufferRequest(TestConst.PERSIST_BUCKET, 'fake/duplicate'));
        // 只应认第一次 complete，返回首个 data 分片
        expect(result?.byteLength).assertEqual(4);
      } catch (e) {
        TestUtils.printError(e as CosError);
        expect().assertFail();
      }
      done();
    })

    it('fake_cancelBeatsFailure', 0, async (done: Function) => {
      // 底层 cancel 同步触发 onFailure：用户取消应稳定得到 USER_CANCELLED，且不触发重试
      let client = new FakeNetworkClient(() => (req, h, proxy) => {
        // 不主动完成；当 SDK 调用 cancel() 时，模拟网络库把取消当成失败回调
        proxy.onCancel = () => {
          h.onFailure(new Error('aborted by cancel'));
        };
      });
      let service = fakeService(client, 3);
      let request = new GetObjectArrayBufferRequest(TestConst.PERSIST_BUCKET, 'fake/cancelRace');
      setTimeout(() => {
        service.cancel(request);
      }, 150);
      try {
        await service.getObjectToArrayBuffer(request);
        expect().assertFail();
      } catch (e) {
        expect((e as CosError).cosErrorCode).assertEqual(CosErrorCode.USER_CANCELLED);
        // 只应创建一个代理（取消不触发重试）
        expect(client.proxies.length).assertEqual(1);
      }
      done();
    })

    it('fake_retryCreatesNewProxy', 0, async (done: Function) => {
      // 网络错误重试：每次重试都应获取新的 NetworkProxy 实例，且 init 只调用一次
      let client = new FakeNetworkClient(() => (req, h) => {
        h.onFailure(new Error('net fail'));
      });
      let service = fakeService(client, 2);
      let failed = false;
      try {
        await service.getObjectToArrayBuffer(
          new GetObjectArrayBufferRequest(TestConst.PERSIST_BUCKET, 'fake/retry'));
      } catch (e) {
        failed = true;
      }
      expect(failed).assertTrue();
      // 1 次首发 + 2 次重试 = 3 个代理
      expect(client.proxies.length).assertEqual(3);
      // NetworkClient 只初始化一次
      expect(client.initCount).assertEqual(1);
      done();
    })

    it('fake_concurrentNoCrossTalk', 0, async (done: Function) => {
      // 并发多任务：按 url 返回不同大小的数据，验证事件按 taskId 隔离、互不串扰
      let client = new FakeNetworkClient(() => (req, h) => {
        let size = req.url.includes('fake/kA') ? 1 : (req.url.includes('fake/kB') ? 2 : 3);
        h.onResponseHeaders({});
        h.onData(new ArrayBuffer(size));
        h.onComplete(200);
      });
      let service = fakeService(client, 0);
      try {
        let results = await Promise.all([
          service.getObjectToArrayBuffer(new GetObjectArrayBufferRequest(TestConst.PERSIST_BUCKET, 'fake/kA')),
          service.getObjectToArrayBuffer(new GetObjectArrayBufferRequest(TestConst.PERSIST_BUCKET, 'fake/kB')),
          service.getObjectToArrayBuffer(new GetObjectArrayBufferRequest(TestConst.PERSIST_BUCKET, 'fake/kC'))
        ]);
        expect(results[0]?.byteLength).assertEqual(1);
        expect(results[1]?.byteLength).assertEqual(2);
        expect(results[2]?.byteLength).assertEqual(3);
        // 5 个并发请求（此处 3 个）共用一个 client，init 只调用一次
        expect(client.initCount).assertEqual(1);
      } catch (e) {
        TestUtils.printError(e as CosError);
        expect().assertFail();
      }
      done();
    })
  })

  // ==================== 默认 rcp 网络层数据完整性（兼容性回归）====================
  // 验证解耦 rcp（dataEnd 时机变化）后，默认路径大文件多分片下载数据仍然完整。
  describe('defaultNetworkIntegrityTest', () => {
    let defaultService: CosXmlBaseService;

    beforeAll(() => {
      // 不设置 networkClient，使用默认 rcp 实现
      let config = new CosXmlServiceConfig(TestConst.PERSIST_BUCKET_REGION);
      defaultService = new CosXmlBaseService(TestUtils.getContext(), config, Credential.constCredential);
    })

    it('default_multipartUpload_downloadBack_integrity', 0, async (done: Function) => {
      let filesDir = TestUtils.getContext().filesDir;
      // 5MB，触发分片上传，且下载时产生多次分片回调（覆盖 dataEnd/finish 时序）
      let srcPath = FileUtils.getFile(5 * 1024 * 1024, 'defaultMultipartSrc');
      let cosKey = 'do_not_remove/default_net_multipart.bin';
      let downloadPath = filesDir + '/default_net_multipart_back.bin';

      let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, cosKey, srcPath);
      let uploadTask: UploadTask = defaultService.upload(putRequest);
      uploadTask.onResult = {
        onSuccess: async (req, result) => {
          try {
            let getRequest = new GetObjectRequest(TestConst.PERSIST_BUCKET, cosKey, downloadPath);
            let dl = await defaultService.getObject(getRequest);
            if (!(dl.httpCode && dl.httpCode >= 200 && dl.httpCode < 300)) {
              expect().assertFail();
              done();
              return;
            }
            let srcCrc = await CRC64.crc64File(srcPath);
            let downCrc = await CRC64.crc64File(downloadPath);
            Logger.info(`default integrity srcCrc=${srcCrc} downCrc=${downCrc}`);
            expect(srcCrc === downCrc).assertTrue();
          } catch (e) {
            TestUtils.printError(e as CosError);
            expect().assertFail();
          }
          done();
        },
        onFail: (req, error) => {
          TestUtils.printError(error);
          expect().assertFail();
          done();
        }
      };
      uploadTask.start();
    })
  })
}
