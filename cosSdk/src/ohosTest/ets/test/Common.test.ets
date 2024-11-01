import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, Size } from '@ohos/hypium';
import {
  CryptoUtil,
  HttpRequest,
  QCloudCredential,
  QCloudHttpRequest,
  QCloudHTTPTask,
  QCloudLogger,
  QCloudNetError, QCloudTaskError, QCloudTaskManager, QCloudTask, QCloudEventType, QCloudTransferData, TaskHTTPExecuteFunc,
  RetryHandler, LoggerOptions, CredentialCache,
  StringUtils, XmlUtils } from '@tencentcloud/foundation';
import { CosError, CosErrorCode, CosXmlBaseService,
  CosXmlServiceConfig,
  CredentialCallBack,
  GetObjectResult,
  HttpProgress,
  ListPartsRequest} from '../../../../Index';
import { TestConst } from './common/TestConst';
import { hilog } from '@kit.PerformanceAnalysisKit';
import http from '@ohos.net.http';
import { ResponseArrayBufferConverter } from '../../../main/ets/converter/ResponseArrayBufferConverter';


export default function commonTest(cosXmlBaseService: CosXmlBaseService) {
  describe('commonTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    })
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    })
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    })
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    })
    it('parseBool', 0, async (done: Function) => {
      let result = StringUtils.parseInt('1');
      let result1 = StringUtils.parseInt(1);

      let result2 = StringUtils.parseBool('true');

      let result3 = StringUtils.parseBool(1);

      let result4 = StringUtils.parseBool(undefined);

      let result5 = StringUtils.parseBool(true);
      done()
    })

    it('ParseXml', 0, async (done: Function) => {
      try {
        let xml =  '<ListPartsResult>' +
          '<Bucket>tinna-media-1253960454</Bucket>' +
          '<EncodingType/>' +
          '<Key>uploadTest/shaofu.mp4</Key>' +
          '<UploadId>1718106898a6eabbe9890053332fee76f72ae0ee704a0e5af5ff49e47d328562e0b6b21946</UploadId>' +
          '<Owner>' +
          '<ID>1253960454</ID>' +
          '<DisplayName>1253960454</DisplayName>' +
          '</Owner>' +
          '<PartNumberMarker>0</PartNumberMarker>' +
          '<Initiator>' +
          '<ID>qcs::cam::uin/2832742109:uin/2832742109</ID>' +
          '<DisplayName>2832742109</DisplayName>' +
          '</Initiator>' +
          '<Part>' +
          '<PartNumber>1</PartNumber>' +
          '<LastModified>2024-06-11T11:55:01.000Z</LastModified>' +
          '<ETag>&quot;3b452616f8974ababa69a0b27c38771b&quot;</ETag>' +
          '<Size>1048576</Size>' +
          '</Part>' +
          '<StorageClass>Standard</StorageClass>' +
          '<MaxParts>1000</MaxParts>' +
          '<IsTruncated>false</IsTruncated>' +
          '</ListPartsResult>'
        let result = XmlUtils.xml2obj(xml)
      }catch (e){
        console.log(e);
      }
      done()
    })

    it('ParseXml1', 0, async (done: Function) => {
      try {
        let xml =  '<ListPartsResult>' +
          '<Bucket>tinna-media-1253960454</Bucket>' +
          '<EncodingType/>' +
          '<Key>uploadTest/shaofu.mp4</Key>' +
          '<UploadId>1718106898a6eabbe9890053332fee76f72ae0ee704a0e5af5ff49e47d328562e0b6b21946</UploadId>' +
          '<Owner>' +
          '<ID>1253960454</ID>' +
          '<DisplayName>1253960454</DisplayName>' +
          '</Owner>' +
          '<PartNumberMarker>0</PartNumberMarker>' +
          '<Initiator>' +
          '<ID>qcs::cam::uin/2832742109:uin/2832742109</ID>' +
          '<DisplayName>2832742109</DisplayName>' +
          '</Initiator>' +
          '<Part>' +
          '<PartNumber>1</PartNumber>' +
          '<LastModified>2024-06-11T11:55:01.000Z</LastModified>' +
          '<ETag>&quot;3b452616f8974ababa69a0b27c38771b&quot;</ETag>' +
          '<Size>1048576</Size>'
        let result = XmlUtils.xml2obj(xml)
      }catch (e){
        console.log(e);
      }
      done();
    })

    it('taskManager', 0, async (done: Function) => {
      QCloudTaskManager.manager().getRunningTask(33333);
      QCloudTaskManager.manager().setDownloadConcurrentCount(1);
      QCloudTaskManager.manager().setUploadConcurrentCount(1);
      QCloudTaskManager.manager().setRequestConcurrentCount(1);
      QCloudTaskManager.manager().cancelAll();
      done();
    })

    it('netError', 0, async (done: Function) => {
      let netError = new QCloudNetError(Error("netError"));
      let taskError = new QCloudTaskError(Error("netError"));
      done();
    })

    it('credential', 0, async (done: Function) => {
      let credential = new QCloudCredential();
      credential.valid();

      credential.expirationDate = new Date();
      credential.valid();
      done();
    })

    it('paramsError', 0, async (done: Function) => {
      let handle = new RetryHandler(3,1);
      handle.reset();

      handle.shouldRetry();
      handle.shouldRetry();
      handle.shouldRetry();
      handle.shouldRetry();
      handle.copy();

      done();
    })

    it('onTaskReceiveData', 0, async (done: Function) => {

      let data = new QCloudTransferData(QCloudEventType.netError,null,null);

      let task = new QCloudTask(TaskHTTPExecuteFunc)

      task.getRequestData();
      await task.buildRequestData();

      task.reset();

      task.onTaskReceiveData(data);

      task.shouldRetry(Error("test"));
      done();
    })

    it('authentation', 0, async (done: Function) => {

      CredentialCache.singleCache().clearCredential();
      done();
    })

    it('logger', 0, async (done: Function) => {

      let option  = new LoggerOptions();
      option.tag = "utTest";
      option.domain = 0x666;
      option.close = false;
      option.isHilog = true;
      option.showLogLocation = true;
      option.logSize = 1;
      let logger = QCloudLogger.init(option);
      QCloudLogger.isLoggable(hilog.LogLevel.DEBUG);
      QCloudLogger.warn('test','ut')
      QCloudLogger.fatal('test','ut')

      option.tag = "utTest";
      option.domain = 0x666;
      option.close = false;
      option.isHilog = false;
      option.showLogLocation = true;
      option.logSize = 1;
      QCloudLogger.init(option);
      QCloudLogger.isLoggable(hilog.LogLevel.DEBUG);
      QCloudLogger.debug('test','ut')
      QCloudLogger.info('test','ut')
      QCloudLogger.error('test','ut')
      QCloudLogger.warn('test','ut')
      QCloudLogger.fatal('test','ut')
      QCloudLogger.log('test','ut')



      option.close = true;
      option.isHilog = false;
      option.showLogLocation = true;
      option.logSize = 1;
      QCloudLogger.init(option);
      QCloudLogger.isLoggable(hilog.LogLevel.DEBUG);
      QCloudLogger.debug('test','ut')
      QCloudLogger.info('test','ut')
      QCloudLogger.error('test','ut')
      QCloudLogger.warn('test','ut')
      QCloudLogger.fatal('test','ut')
      QCloudLogger.log('test','ut')
      done();
    })
    it('HttpRequest', 0, async (done: Function) => {
      let httpRequest = new HttpRequest<object>(http.RequestMethod.GET, "https", "host", 80, "path.txt", undefined,
        new ResponseArrayBufferConverter<object>(new GetObjectResult()),undefined, undefined, undefined, undefined);
      httpRequest.addQuery("aaa", "aaa");
      httpRequest.getQuery("aaa");
      httpRequest.removeQuery("aaa");
      httpRequest.addNoSignHeaderKey("aaa");
      httpRequest.addNoSignQueryKey("aaa");
      httpRequest.setUserAgent("ua");

      done();
    })
    it('other', 0, async (done: Function) => {
      CryptoUtil.qcloudMd5Str("asdasd");
      XmlUtils.obj2xml([]);
      XmlUtils.obj2xml(new Object())

      done();
    })
  })
}
