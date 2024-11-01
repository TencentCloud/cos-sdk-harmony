import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, Size } from '@ohos/hypium';
import { CosError, CosErrorCode, CosXmlBaseService,
  CosXmlServiceConfig,
  CredentialCallBack,
  HttpProgress } from '../../../../../Index';
import { GetObjectRequest } from '../../../../main/ets/model/object/GetObjectRequest';
import { CosXmlDownloadTaskResult, DownloadTask } from '../../../../main/ets/transfer/DownloadTask';
import { CRC64 } from '../common/CRC64';
import { Logger } from '../common/Logger';
import { TestConst } from '../common/TestConst';
import { TestUtils } from '../common/TestUtils';
import fs from '@ohos.file.fs';

export default function downloadTest(cosXmlBaseService: CosXmlBaseService) {
  describe('downloadTest', () => {
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
    it('small', 0, async (done: Function) => {
      let context = TestUtils.getContext();
      let filePath = context.filesDir + '/image.png';
      let request = new GetObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_PATH, filePath);
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let downloadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).download(request);
      downloadTask.onProgress = (progress: HttpProgress)=>{
        Logger.info(`已下载：${progress.complete}，总大小：${progress.target}`)
      }
      downloadTask.onResult = {
        onSuccess: async (request: GetObjectRequest, result: CosXmlDownloadTaskResult)=>{
          Logger.info(`下载成功：`)
          Logger.info(result)
          let fileHash = (await CRC64.crc64File(filePath)).toString();
          Logger.info(`计算成功：`)
          let crc64ecma: string = "";
          if(result.headers){
            crc64ecma = result.headers["x-cos-hash-crc64ecma"];
          }
          Logger.info(`crc64：本地文件crc64为${fileHash} x-cos-hash-crc64ecma为${crc64ecma}`)
          if(fileHash === crc64ecma){
            Logger.info(`crc64校验成功`)
            expect(true).assertTrue();
          } else {
            Logger.info(`crc64校验失败`)
            expect().assertFail();
          }
          done();
        },
        onFail: (request: GetObjectRequest, error: CosError)=>{
          Logger.info(`下载失败：`)
          TestUtils.printError(error);
          expect().assertFail();
          done();
        }
      }
      downloadTask.start();
    })
    it('big_10m', 0, async (done: Function) => {
      let context = TestUtils.getContext();
      let filePath = context.filesDir + '/big_object';
      let request = new GetObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_BIG_10M_PATH, filePath);
      // 设置单链接限速，单位为 bit/s，示例设置为 1M/s
      request.addHeader("x-cos-traffic-limit", (1024 * 1024 * 8).toString());
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let downloadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).download(request);
      downloadTask.onProgress = (progress: HttpProgress)=>{
        Logger.info(`已下载：${progress.complete}，总大小：${progress.target}`)
      }
      downloadTask.onResult = {
        onSuccess: async (request: GetObjectRequest, result: CosXmlDownloadTaskResult)=>{
          Logger.info(`下载成功：`)
          Logger.info(result)
          let fileHash = (await CRC64.crc64File(filePath)).toString();
          Logger.info(`计算成功：`)
          let crc64ecma: string = "";
          if(result.headers){
            crc64ecma = result.headers["x-cos-hash-crc64ecma"];
          }
          Logger.info(`crc64：本地文件crc64为${fileHash} x-cos-hash-crc64ecma为${crc64ecma}`)
          if(fileHash === crc64ecma){
            Logger.info(`crc64校验成功`)
            expect(true).assertTrue();
          } else {
            Logger.info(`crc64校验失败`)
            expect().assertFail();
          }
          done();
        },
        onFail: (request: GetObjectRequest, error: CosError)=>{
          Logger.info(`下载失败：`)
          TestUtils.printError(error);
          expect().assertFail();
          done();
        }
      }
      downloadTask.start();
    })
    // it('big', 0, async (done: Function) => {
    //   let context = TestUtils.getContext();
    //   let filePath = context.filesDir + '/522m.zip';
    //   let config = new CosXmlServiceConfig(TestConst.PERSIST_BUCKET_REGION);
    //   config.readTimeout = 1500 * 1000;
    //   let request = new GetObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_BIG_FILE_PATH, filePath);
    //   let credentialCallBack: CredentialCallBack|undefined;
    //   if(cosXmlBaseService){
    //     credentialCallBack = cosXmlBaseService.credentialCallBack;
    //   } else {
    //     credentialCallBack = CosXmlBaseService.default().credentialCallBack;
    //   }
    //   let cosBaseService = new CosXmlBaseService(context, config, credentialCallBack);
    //   await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosBaseService));
    //   let downloadTask = cosBaseService.download(request);
    //   downloadTask.onProgress = (progress: HttpProgress)=>{
    //     Logger.info(`已下载：${progress.complete}，总大小：${progress.target}`)
    //   }
    //   downloadTask.onResult = {
    //     onSuccess: async (request: GetObjectRequest, result: CosXmlDownloadTaskResult)=>{
    //       Logger.info(`下载成功：`)
    //       Logger.info(result)
    //       // let fileHash = (await CRC64.crc64File(filePath)).toString();
    //       // Logger.info(`计算成功：`)
    //       // let crc64ecma: string = "";
    //       // if(result.headers){
    //       //   crc64ecma = result.headers["x-cos-hash-crc64ecma"];
    //       // }
    //       // Logger.info(`crc64：本地文件crc64为${fileHash} x-cos-hash-crc64ecma为${crc64ecma}`)
    //       // if(fileHash === crc64ecma){
    //       //   Logger.info(`crc64校验成功`)
    //       //   expect(true).assertTrue();
    //       // } else {
    //       //   Logger.info(`crc64校验失败`)
    //       //   expect().assertFail();
    //       // }
    //       expect(true).assertTrue();
    //       done();
    //     },
    //     onFail: (request: GetObjectRequest, error: CosError)=>{
    //       Logger.info(`下载失败：`)
    //       TestUtils.printError(error);
    //       expect().assertFail();
    //       done();
    //     }
    //   }
    //   downloadTask.start();
    // })
    it('pauseResume', 0, async (done: Function) => {
      let context = TestUtils.getContext();
      let filePath = context.filesDir + '/big_object';
      let config = new CosXmlServiceConfig(TestConst.PERSIST_BUCKET_REGION);
      config.readTimeout = 1500 * 1000;
      let request = new GetObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_BIG_10M_PATH, filePath);
      let credentialCallBack: CredentialCallBack|undefined;
      if(cosXmlBaseService){
        credentialCallBack = cosXmlBaseService.credentialCallBack;
      } else {
        credentialCallBack = CosXmlBaseService.default().credentialCallBack;
      }
      let cosBaseService = new CosXmlBaseService(context, config, credentialCallBack);
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosBaseService));
      let task = cosBaseService.download(request);
      let paused:boolean;
      task.onProgress = (progress: HttpProgress) => {
        if (progress.complete > 5 * 1024 * 1024 && !paused) {
          paused = true;
          task.pause();
          Logger.info(`PauseResume:pause`)
          setTimeout(()=>{
            Logger.info(`PauseResume:resume`)
            task.resume();
          },1000);
        }
      };
      task.onResult = {
        onSuccess: (request, result) => {
          Logger.info(`PauseResume:success:${JSON.stringify(result,null,2)}`)
          expect(true).assertTrue();
          done();
        },
        onFail: (request, error) => {
          TestUtils.printError(error);
          if (error.cosErrorCode != CosErrorCode.USER_PAUSED) {
            expect().assertFail();
            done();
          }
        }
      }
      task.start();
    })
    it('cancel', 0, async (done: Function) => {
      let context = TestUtils.getContext();
      let filePath = context.filesDir + '/big_object';
      let config = new CosXmlServiceConfig(TestConst.PERSIST_BUCKET_REGION);
      config.readTimeout = 1500 * 1000;
      let request = new GetObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_BIG_10M_PATH, filePath);
      let credentialCallBack: CredentialCallBack|undefined;
      if(cosXmlBaseService){
        credentialCallBack = cosXmlBaseService.credentialCallBack;
      } else {
        credentialCallBack = CosXmlBaseService.default().credentialCallBack;
      }
      let cosBaseService = new CosXmlBaseService(context, config, credentialCallBack);
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosBaseService));
      let task = cosBaseService.download(request);
      let cancel = false;
      task.onProgress = (progress: HttpProgress) => {
        if (progress.complete > 5 * 1024 * 1024 && !cancel) {
          task.cancel();
          cancel = true;
        }
      };
      task.onResult = {
        onSuccess: (request, result) => {
          expect().assertFail();
          done();
        },
        onFail: (request, error) => {
          TestUtils.printError(error);
          if (error.cosErrorCode == CosErrorCode.USER_CANCELLED) {
            expect(true).assertTrue();
            done();
          } else {
            expect().assertFail();
            done();
          }
        }
      }
      task.start();
    })
    it('headSuccess', 0, async (done: Function) => {
      let context = TestUtils.getContext();
      let filePath = context.filesDir + '/big_object';
      let config = new CosXmlServiceConfig(TestConst.PERSIST_BUCKET_REGION);
      config.readTimeout = 1500 * 1000;
      let request = new GetObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_BIG_10M_PATH, filePath);
      let credentialCallBack: CredentialCallBack|undefined;
      if(cosXmlBaseService){
        credentialCallBack = cosXmlBaseService.credentialCallBack;
      } else {
        credentialCallBack = CosXmlBaseService.default().credentialCallBack;
      }
      let cosBaseService = new CosXmlBaseService(context, config, credentialCallBack);
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosBaseService));
      let task = cosBaseService.download(request);
      let paused:boolean;
      task.onProgress = (progress: HttpProgress) => {
        if (progress.complete > 5 * 1024 * 1024 && !paused) {
          paused = true;
          task.pause();

          let fileSize = (fs.statSync(filePath)).size;
          request.setRange(fileSize, -1);
          request.fileOffset = fileSize;
          let task1 = cosBaseService.download(request);
          task1.onResult = {
            onSuccess: (request, result) => {
              Logger.info(`PauseResume:resume`)
              task.resume();
            },
            onFail: (request, error) => {
              TestUtils.printError(error);
              expect().assertFail();
              done();
            }
          }
          task1.start();
        }
      };
      task.onResult = {
        onSuccess: (request, result) => {
          Logger.info(`PauseResume:success:${JSON.stringify(result,null,2)}`)
          expect(true).assertTrue();
          done();
        },
        onFail: (request, error) => {
          TestUtils.printError(error);
          if (error.cosErrorCode != CosErrorCode.USER_PAUSED) {
            expect().assertFail();
            done();
          }
        }
      }
      task.start();
    })
    it('simpleBatch', 0, async (done: Function) => {
      let count = 10;
      let context = TestUtils.getContext();
      let successCount = 0;
      for (let index = 0; index < count; index++) {
        let filePath = context.filesDir + '/bigFile' + index;
        let request = new GetObjectRequest(TestConst.PERSIST_BUCKET, "uploadTest/UT/bigFile"+index, filePath);
        await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
        let downloadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).download(request);
        downloadTask.onResult = {
          onSuccess: async (request: GetObjectRequest, result: CosXmlDownloadTaskResult)=>{
            Logger.info(result)
            successCount++;
            if(successCount===count){
              expect(true).assertTrue();
              done();
            }
          },
          onFail: (request: GetObjectRequest, error: CosError)=>{
            Logger.info(`下载失败：`)
            TestUtils.printError(error);
            expect().assertFail();
            done();
          }
        }
        downloadTask.start();
      }
    })
    it('ci', 0, async (done: Function) => {
      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request = new GetObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_PATH, filesDir + '/image.png');
      request.addQuery("imageMogr2/rotate/70");
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let downloadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).download(request);
      downloadTask.onProgress = (progress: HttpProgress)=>{
        Logger.info(`已下载：${progress.complete}，总大小：${progress.target}`)
      }
      downloadTask.onResult = {
        onSuccess: (request: GetObjectRequest, result: CosXmlDownloadTaskResult)=>{
          Logger.info(`下载成功：`)
          Logger.info(result)
          expect(true).assertTrue();
          done();
        },
        onFail: (request: GetObjectRequest, error: CosError)=>{
          Logger.info(`下载失败：`)
          TestUtils.printError(error);
          expect().assertFail();
          done();
        }
      }
      downloadTask.start();
    })
    it('ciBig', 0, async (done: Function) => {
      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request = new GetObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_6M_PATH, filesDir + '/6m.jpg');
      request.addQuery("imageMogr2/rotate/70");
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let downloadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).download(request);
      downloadTask.onProgress = (progress: HttpProgress)=>{
        Logger.info(`已下载：${progress.complete}，总大小：${progress.target}`)
      }
      downloadTask.onResult = {
        onSuccess: (request: GetObjectRequest, result: CosXmlDownloadTaskResult)=>{
          Logger.info(`下载成功：`)
          Logger.info(result)
          expect(true).assertTrue();
          done();
        },
        onFail: (request: GetObjectRequest, error: CosError)=>{
          Logger.info(`下载失败：`)
          TestUtils.printError(error);
          expect().assertFail();
          done();
        }
      }
      downloadTask.start();
    })
    it('errorDownload', 0, async (done: Function) => {
      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request = new GetObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_PATH, 'error' + filesDir + '/test.txt');
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let downloadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).download(request);
      downloadTask.onProgress = (progress: HttpProgress)=>{
        Logger.info(`已下载：${progress.complete}，总大小：${progress.target}`)
      }
      downloadTask.onResult = {
        onSuccess: (request: GetObjectRequest, result: CosXmlDownloadTaskResult)=>{
          expect().assertFail();
          done();
        },
        onFail: (request: GetObjectRequest, error: CosError)=>{
          Logger.info(`下载失败：`)
          TestUtils.printError(error);
          expect(true).assertTrue();
          done();
        }
      }
      downloadTask.start();
    })
    it('errorDownload1', 0, async (done: Function) => {
      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request = new GetObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_PATH+"aaaError", filesDir + '/test.txt');
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let downloadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).download(request);
      downloadTask.onProgress = (progress: HttpProgress)=>{
        Logger.info(`已下载：${progress.complete}，总大小：${progress.target}`)
      }
      downloadTask.onResult = {
        onSuccess: (request: GetObjectRequest, result: CosXmlDownloadTaskResult)=>{
          expect().assertFail();
          done();
        },
        onFail: (request: GetObjectRequest, error: CosError)=>{
          Logger.info(`下载失败：`)
          TestUtils.printError(error);
          expect(true).assertTrue();
          done();
        }
      }
      downloadTask.start();
    })
    it('bigTimeOut', 0, async (done: Function) => {
      let context = TestUtils.getContext();
      let filePath = context.filesDir + '/522m.zip';
      let request = new GetObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_BIG_FILE_PATH, filePath);
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(TestUtils.getCosXmlBaseService(cosXmlBaseService)));
      let downloadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).download(request);
      downloadTask.onResult = {
        onSuccess: async (request: GetObjectRequest, result: CosXmlDownloadTaskResult)=>{
          Logger.info(result)
          expect().assertFail();
          done();

        },
        onFail: (request: GetObjectRequest, error: CosError)=>{
          TestUtils.printError(error);
          if (error.cosErrorCode == CosErrorCode.NETWORK) {
            expect(true).assertTrue();
            done();
          } else {
            expect().assertFail();
            done();
          }
        }
      }
      downloadTask.start();
    })
  })
}