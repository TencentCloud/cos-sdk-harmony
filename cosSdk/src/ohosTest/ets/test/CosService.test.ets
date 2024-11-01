import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { CosError, CosErrorCode, CosXmlBaseService, CosXmlServiceConfig,
  DeleteObjectRequest,
  PresignedUrlRequest,
  PutObjectRequest,
  UploadTask} from '../../../../Index';
import { GetObjectArrayBufferRequest } from '../../../main/ets/model/object/GetObjectArrayBufferRequest';
import { GetObjectRequest } from '../../../main/ets/model/object/GetObjectRequest';
import { HeadObjectRequest } from '../../../main/ets/model/object/HeadObjectRequest';
import { Logger } from './common/Logger';
import { TestConst } from './common/TestConst';
import { TestUtils } from './common/TestUtils';
import http from '@ohos.net.http';
import { CredentialCallBack, HttpHeader, QCloudCredential, CredentialCache } from '@tencentcloud/foundation';
import { BusinessError } from '@ohos.base';
import { FileUtils } from './common/FileUtils';
import { StsSessionQCloudCredentials } from './common/Credential';

export default function cosServiceTest(cosXmlBaseService: CosXmlBaseService) {
  describe('cosServiceTest', () => {
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
    it('headObject', 0, async (done: Function) => {
      let request = new HeadObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_PATH);
      // request.addNoSignHeaderKey(HttpHeader.HOST)
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).headObject(request)
        Logger.info(result)
        if(result.eTag()){
          let cosObjectType = result.cosObjectType()
          if(cosObjectType){
            Logger.info(cosObjectType)
          }
          let cosStorageClass = result.cosStorageClass()
          if(cosStorageClass){
            Logger.info(cosStorageClass)
          }
          expect(true).assertTrue();
        } else {
          expect().assertFail();
        }
      } catch (e) {
        TestUtils.printError(e);
        expect().assertFail();
      }
      done();
    })
    it('getObject', 0, async (done: Function) => {
      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request = new GetObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_PATH, filesDir + '/test.jpg');
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).getObject(request)
        Logger.info(result)
        if(result.httpCode && result.httpCode >= 200 && result.httpCode < 300){
          expect(true).assertTrue();
        } else {
          expect().assertFail();
        }
      } catch (e) {
        TestUtils.printError(e);
        expect().assertFail();
      }
      done();
    })
    it('getObjectToArrayBuffer', 0, async (done: Function) => {
      let request = new GetObjectArrayBufferRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_PATH);
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).getObjectToArrayBuffer(request)
        if(result && result.byteLength > 0){
          Logger.info(result.byteLength.toString())
          expect(true).assertTrue();
        } else {
          expect().assertFail();
        }
      } catch (e) {
        TestUtils.printError(e);
        expect().assertFail();
      }
      done();
    })
    it('getObjectCancel', 0, async (done: Function) => {
      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request = new GetObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_PATH, filesDir + '/test.jpg');
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        request.onProgress = (httpProgress) => {
          if(httpProgress.complete / httpProgress.target > 0.1){
            TestUtils.getCosXmlBaseService(cosXmlBaseService).cancel(request)
          }
        }
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).getObject(request)
        Logger.info(result)
        expect().assertFail();
      } catch (e) {
        TestUtils.printError(e);
        if((e as CosError).cosErrorCode === CosErrorCode.USER_CANCELLED){
          expect(true).assertTrue();
        } else {
          expect().assertFail();
        }
      }
      done();
    })
    it('deleteObject', 0, async (done: Function) => {
      let filePath = FileUtils.getFile(500 * 1024,'simpleUpload');
      let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/deleteFile`, filePath);
      await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let task: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest);
      task.onResult = {
        onSuccess: async (request, result) => {
          let deleteObjectRequest = new DeleteObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/deleteFile`);
          await TestUtils.requestAddCredential(deleteObjectRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
          try {
            let deleteResult = await TestUtils.getCosXmlBaseService(cosXmlBaseService).deleteObject(deleteObjectRequest)
            Logger.info(deleteResult)
            if(deleteResult.httpCode && deleteResult.httpCode >= 200 && deleteResult.httpCode < 300){
              expect(true).assertTrue();
            } else {
              expect().assertFail();
            }
          } catch (e) {
            TestUtils.printError(e);
            expect().assertFail();
          }
          done();
        },
        onFail: (request, error) => {
          Logger.info(`simpleUpload_fail`)
          Logger.info(error)
          expect().assertFail()
          done();
        }
      }
      task.start();
    })
    // it('getObjectCancelAll', 0, async (done: Function) => {
    //
    // })
    it('presignedPut', 0, async (done: Function) => {
      let request = new PresignedUrlRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PUT_PATH, http.RequestMethod.PUT);
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).buildPresignedUrl(request)
        Logger.info(result)
        if(result){
          let httpRequest = http.createHttp();
          try {
            let data = await httpRequest.request(result, { method: http.RequestMethod.PUT, extraData: 'data to put' });
            if (data.responseCode >= 200 && data.responseCode < 300) {
              httpRequest.destroy();
              expect(true).assertTrue();
            } else {
              httpRequest.destroy();
              expect().assertFail();
            }
          } catch (err) {
            Logger.error(err);
            httpRequest.destroy();
            expect().assertFail();
          }
        } else {
          expect().assertFail();
        }
      } catch (e) {
        TestUtils.printError(e);
        expect().assertFail();
      }
      done();
    })
    it('presignedGet', 0, async (done: Function) => {
      let request = new PresignedUrlRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_PATH, http.RequestMethod.GET);
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).buildPresignedUrl(request)
        Logger.info(result)
        if(result){
          let httpRequest = http.createHttp();
          try {
            let data = await httpRequest.request(result, { method: http.RequestMethod.GET });
            if (data.responseCode >= 200 && data.responseCode < 300) {
              httpRequest.destroy();
              expect(true).assertTrue();
            } else {
              httpRequest.destroy();
              expect().assertFail();
            }
          } catch (err) {
            Logger.error(err);
            httpRequest.destroy();
            expect().assertFail();
          }
        } else {
          expect().assertFail();
        }
      } catch (e) {
        TestUtils.printError(e);
        expect().assertFail();
      }
      done();
    })
    it('bucket_must_not_be_null', 0, async (done: Function) => {
      let request = new HeadObjectRequest("", TestConst.PERSIST_BUCKET_PIC_PATH);
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).headObject(request)
        expect().assertFail();
      } catch (e) {
        TestUtils.printError(e);
        expect((e as CosError).message === "bucket must not be null ").assertTrue();
      }
      done();
    })
    it('cosPath_must_not_be_null', 0, async (done: Function) => {
      let request = new HeadObjectRequest(TestConst.PERSIST_BUCKET, "");
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).headObject(request)
        expect().assertFail();
      } catch (e) {
        TestUtils.printError(e);
        expect((e as CosError).message === "cosPath must not be null ").assertTrue();
      }
      done();
    })
    it('bucket_must_not_be_null1', 0, async (done: Function) => {
      let request = new PresignedUrlRequest("", TestConst.PERSIST_BUCKET_PIC_PATH, http.RequestMethod.GET);
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).buildPresignedUrl(request)
        expect().assertFail();
      } catch (e) {
        TestUtils.printError(e);
        expect((e as CosError).message === "bucket must not be null ").assertTrue();
      }
      done();
    })
    it('cosPath_must_not_be_null1', 0, async (done: Function) => {
      let request = new PresignedUrlRequest(TestConst.PERSIST_BUCKET, "", http.RequestMethod.GET);
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).buildPresignedUrl(request)
        expect().assertFail();
      } catch (e) {
        TestUtils.printError(e);
        expect((e as CosError).message === "cosPath must not be null ").assertTrue();
      }
      done();
    })
    it('headObjectIsSignedInURL', 0, async (done: Function) => {
      let request = new HeadObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_PATH);
      request.isSignedInURL = true;
      // request.addNoSignHeaderKey(HttpHeader.HOST)
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).headObject(request)
        Logger.info(result)
        if(result.eTag()){
          let cosObjectType = result.cosObjectType()
          if(cosObjectType){
            Logger.info(cosObjectType)
          }
          let cosStorageClass = result.cosStorageClass()
          if(cosStorageClass){
            Logger.info(cosStorageClass)
          }
          expect(true).assertTrue();
        } else {
          expect().assertFail();
        }
      } catch (e) {
        TestUtils.printError(e);
        expect().assertFail();
      }
      done();
    })
    it('headObjectAuthenticationError', 0, async (done: Function) => {
      let sessionCredential: CredentialCallBack = (request)=> {
        return new Promise((resolve, reject) => {
          let httpRequest = http.createHttp();
          httpRequest.request(
            "http://66.66.66.66/stssss",
            { method: http.RequestMethod.GET },
            (err: BusinessError, data: http.HttpResponse) => {
              if (!err) {
                Logger.info(data, "QCloudCredentials_Response")

                const stsSessionQCloudCredentials: StsSessionQCloudCredentials = JSON.parse(data.result.toString());
                let credential : QCloudCredential= new QCloudCredential();
                credential.secretID = stsSessionQCloudCredentials.credentials.tmpSecretId;
                credential.secretKey = stsSessionQCloudCredentials.credentials.tmpSecretKey;
                credential.token = stsSessionQCloudCredentials.credentials.sessionToken;
                credential.startDate = new Date(stsSessionQCloudCredentials.startTime * 1000);
                credential.expirationDate = new Date(stsSessionQCloudCredentials.expiredTime * 1000);
                httpRequest.destroy();
                resolve(credential)
              } else {
                Logger.info(`临时秘钥获取失败：`)
                Logger.error(err)
                httpRequest.destroy();
                reject(err)
              }
            });
        })
      }
      let service = new CosXmlBaseService(
        TestUtils.getContext(),
        new CosXmlServiceConfig(TestConst.PERSIST_BUCKET_REGION),
        sessionCredential
      )
      CredentialCache.singleCache().clearCredential();
      let request = new HeadObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_PATH);
      try {
        let result = await service.headObject(request)
        expect().assertFail();
        done();
      } catch (e) {
        if (e.cosErrorCode == CosErrorCode.INVALID_CREDENTIALS) {
          expect(true).assertTrue();
          done();
        } else {
          expect().assertFail();
          done();
        }
      }
      done();
    })
    // it('cdnDomain', 0, async (done: Function) => {
    //   // 存储桶region可以在COS控制台指定存储桶的概览页查看 https://console.cloud.tencent.com/cos5/bucket/ ，关于地域的详情见 https://cloud.tencent.com/document/product/436/6224
    //   let region = "ap-guangzhou"; // 您的存储桶地域
    //   // 存储桶的默认加速域名
    //   let cdnDomain = "mobile-ut-1253960454.cos.${region}.tencentcos.cn";
    //   // COS服务配置
    //   let cosXmlServiceConfig = new CosXmlServiceConfig(region);
    //   // 修改请求的域名
    //   cosXmlServiceConfig.host = cdnDomain;
    //   // 修改 header 中的 host 字段
    //   cosXmlServiceConfig.headers = new Map();
    //   cosXmlServiceConfig.headers.set("Host", cdnDomain);
    //   // 实例化COS服务cosXmlBaseService
    //   let cosXmlBaseService = new CosXmlBaseService(TestUtils.getContext(), cosXmlServiceConfig);
    //   // 使用cosXmlBaseService进行COS操作
    //
    //   let request = new HeadObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_PATH);
    //   await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
    //   try {
    //     let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).headObject(request)
    //     Logger.info(result)
    //     if(result.eTag()){
    //       let cosObjectType = result.cosObjectType()
    //       if(cosObjectType){
    //         Logger.info(cosObjectType)
    //       }
    //       let cosStorageClass = result.cosStorageClass()
    //       if(cosStorageClass){
    //         Logger.info(cosStorageClass)
    //       }
    //       expect(true).assertTrue();
    //     } else {
    //       expect().assertFail();
    //     }
    //   } catch (e) {
    //     TestUtils.printError(e);
    //     expect().assertFail();
    //   }
    //   done();
    // })

  })
}