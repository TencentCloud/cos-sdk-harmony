import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, Size } from '@ohos/hypium';
import { CosError, CosXmlBaseService,
  CosXmlRequest,
  GetObjectRequest, HttpProgress,
  ListPartsRequest,
  ListPartsResult,
  TransferConfig } from '../../../../../Index';
import { PutObjectRequest } from '../../../../main/ets/model/object/PutObjectRequest';
import { PicOperationRule, PicOperations } from '../../../../main/ets/model/pic/PicOperations';
import { CosXmlDownloadTaskResult } from '../../../../main/ets/transfer/DownloadTask';
import { UploadTask } from '../../../../main/ets/transfer/UploadTask';
import { FileUtils } from '../common/FileUtils';
import { Logger } from '../common/Logger';
import { TestConst } from '../common/TestConst';
import { TestUtils } from '../common/TestUtils';
import { ArrayList } from '@kit.ArkTS';
import { Credential } from '../common/Credential';
import { HttpHeader } from 'foundation';

export default function uploadTest(cosXmlBaseService: CosXmlBaseService) {
  describe('uploadTest', () => {
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

    it('emptyUpload', 0, async (done: Function) => {
      let filePath = FileUtils.getFile(0,'emptyUpload');
      let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/emptyFile`, filePath);
      await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let task: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest);
      task.onProgress = (progress: HttpProgress) => {
        Logger.info(`simpleUpload_onProgress：${progress.complete}/${progress.target}`)
      };
      task.onResult = {
        onSuccess: (request, result) => {
          Logger.info(`simpleUpload_success`)
          Logger.info(result)
          expect(true).assertTrue();
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

    it('simpleUpload', 0, async (done: Function) => {
      let filePath = FileUtils.getFile(500 * 1024,'simpleUpload');
      let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/simpleFile`, filePath);
      // putRequest.addHeader('User-Agent', 'useragent');
      // putRequest.addHeader('Content-Type', 'ContentType');
      await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let task: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest);
      task.onProgress = (progress: HttpProgress) => {
        Logger.info(`simpleUpload_onProgress：${progress.complete}/${progress.target}`)
      };
      task.onResult = {
        onSuccess: (request, result) => {
          Logger.info(`simpleUpload_success`)
          Logger.info(result)
          expect(true).assertTrue();
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

    it('simpleUploadBySign', 0, async (done: Function) => {
      let filePath = FileUtils.getFile(500 * 1024,'bigUpload');

      const signData = await Credential.getSignData('jpg');
      let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, signData.cosKey, filePath);
      putRequest.setSign(signData.authorization, signData.securityToken);
      let task: UploadTask = CosXmlBaseService.default().upload(putRequest);
      task.onProgress = (progress: HttpProgress) => {
        Logger.info(`bigUpload_onProgress：${progress.complete}/${progress.target}`)
      };
      task.onResult = {
        onSuccess: (request, result) => {
          Logger.info(`bigUpload_success`)
          Logger.info(result)
          expect(true).assertTrue();
          done();
        },
        onFail: (request, error) => {
          Logger.info(`bigUpload_fail`)
          Logger.info(error)
          expect().assertFail()
          done();
        }
      }
      task.start();
    })

    it('simpleUploadBySign1', 0, async (done: Function) => {
      let filePath = FileUtils.getFile(500 * 1024,'bigUpload');
      const signData = await Credential.getSignData('jpg');
      let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, signData.cosKey, filePath);
      CosXmlBaseService.default().setSelfSignCallBack(async (request)=>{
        request.addHeader(HttpHeader.AUTHORIZATION, signData.authorization)
        if(signData.securityToken){
          request.addHeader("x-cos-security-token", signData.securityToken)
        }
      })
      let task: UploadTask = CosXmlBaseService.default().upload(putRequest);
      task.onProgress = (progress: HttpProgress) => {
        Logger.info(`bigUpload_onProgress：${progress.complete}/${progress.target}`)
      };
      task.onResult = {
        onSuccess: (request, result) => {
          Logger.info(`bigUpload_success`)
          Logger.info(result)
          expect(true).assertTrue();
          done();
        },
        onFail: (request, error) => {
          Logger.info(`bigUpload_fail`)
          Logger.info(error)
          expect().assertFail()
          done();
        }
      }
      task.start();
    })

    it('simpleUpload_buffer', 0, async (done: Function) => {
      let buffer:ArrayBuffer = new ArrayBuffer(5 * 1024 * 1024);
      let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/simpleFileBuffer`, buffer);
      await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let task: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest);
      task.onProgress = (progress: HttpProgress) => {
        Logger.info(`simpleUpload_onProgress：${progress.complete}/${progress.target}`)
      };
      task.onResult = {
        onSuccess: (request, result) => {
          Logger.info(`simpleUpload_success`)
          Logger.info(result)
          expect(true).assertTrue();
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

    it('simpleUpload_buffer_undefined', 0, async (done: Function) => {
      let buffer = undefined;
      let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/simpleFileBuffer`, buffer);
      await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let task: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest);
      task.onResult = {
        onSuccess: (request, result) => {
          done();
        },
        onFail: (request, error) => {
          Logger.info(`simpleUpload_buffer_undefined_success`)
          Logger.info(error)
          expect(true).assertTrue();
          done();
        }
      }
      task.start();
    })

    it('simpleBatchUpload', 0, async (done: Function) => {
      let filePath = FileUtils.getFile(500 * 1024,'batch');
      let count = 0;
      for (let index = 0; index < 10; index++) {
        let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/simpleFile${index}`, filePath);
        await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
        let task: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest);
        task.onProgress = (progress: HttpProgress) => {
          Logger.info(`simpleBatchUpload_onProgress:File:${index}：${progress.complete}/${progress.target}`)
        };
        task.onResult = {
          onSuccess: (request, result) => {
            Logger.info(`simpleBatchUpload_success:simpleFile${index}`)
            Logger.info(result)
            count ++;
            if (count == 9) {
              expect(true).assertTrue();
              done();
            }
          },
          onFail: (request, error) => {
            Logger.info(`simpleBatchUpload_fail:simpleFile${index}`)
            Logger.info(error)
            expect().assertFail()
            done();
          }
        }
        task.start();
      }
    })

    it('bigUpload', 0, async (done: Function) => {
      let filePath = FileUtils.getFile(100 * 1024 * 1024,'bigUpload');
      let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/bigUpload`, filePath);
      await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let task: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest);
      task.onProgress = (progress: HttpProgress) => {
        Logger.info(`bigUpload_onProgress：${progress.complete}/${progress.target}`)
      };
      task.onResult = {
        onSuccess: (request, result) => {
          Logger.info(`bigUpload_success`)
          Logger.info(result)
          expect(true).assertTrue();
          done();
        },
        onFail: (request, error) => {
          Logger.info(`bigUpload_fail`)
          Logger.info(error)
          expect().assertFail()
          done();
        }
      }
      task.start();
    })

    it('bigBatchUpload', 0, async (done: Function) => {
      let filePath = FileUtils.getFile(20 * 1024 * 1024,'batch');
      let count = 0;
      for (let index = 0; index < 10; index++) {
        let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/bigFile${index}`, filePath);
        await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
        let task: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest);
        task.onProgress = (progress: HttpProgress) => {
          Logger.info(`bigBatchUpload_onProgress:File:${index}：${progress.complete}/${progress.target}`)
        };
        task.onResult = {
          onSuccess: (request, result) => {
            Logger.info(`bigBatchUpload_success:simpleFile${index}`)
            Logger.info(result)
            count ++;
            if (count > 9) {
              expect(true).assertTrue();
              done();
            }
          },
          onFail: (request, error) => {
            Logger.info(`bigBatchUpload_fail:simpleFile${index}`)
            Logger.info(error)
            expect().assertFail()
            done();
          }
        }
        task.start();
      }
    })

    it('uploadPauseResume', 0, async (done: Function) => {
      let filePath = FileUtils.getFile(10 * 1024 * 1024,'resume');
      let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/resumeUpload`, filePath);
      await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let task: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest);
      let paused:boolean;
      task.onProgress = (progress: HttpProgress) => {
        if (progress.complete > 5 * 1024 * 1024 && !paused) {
          task.pause();
          paused = true;
          Logger.info(`uploadPauseResume:pause`)
          setTimeout(()=>{
            Logger.info(`uploadPauseResume:resume`)
            task.resume();
          },1000);
        }
      };
      task.onResult = {
        onSuccess: (request, result) => {
          Logger.info(`uploadPauseResume:success:${JSON.stringify(result,null,2)}`)
          expect(true).assertTrue();
          done();
        },
        onFail: (request, error) => {
          if (paused) {
            Logger.info(error)
            Logger.info(`uploadPauseResume:error:${JSON.stringify(error,null,2)}`)
            expect().assertFail()
            done();
          }
        }
      }
      task.start();
    })

    it('uploadPauseResumeV2', 0, async (done: Function) => {
      let filePath = FileUtils.getFile(10 * 1024 * 1024,'resumeUploadv2');
      let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/resumeUploadV2`, filePath);
      await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let task: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest);
      let _uploadId:string | undefined = undefined;
      task.onProgress = (progress: HttpProgress) => {
        Logger.info(`uploadPauseResumeV2_onProgress:${progress.complete}/${progress.target}`)
        if (progress.complete > 5 * 1024 * 1024) {
          task.pause();
          Logger.info(`uploadPauseResumeV2:pause`)
          setTimeout(async ()=>{
            Logger.info(`uploadPauseResumeV2:resume`)
            if (_uploadId) {
              putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/bigUpload`, filePath);
              await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
              let task1: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest,_uploadId);
              task1.onProgress = (progress: HttpProgress) => {
                Logger.info(`uploadPauseResumeV2_resume_onProgress:${progress.complete}/${progress.target}`)
              };
              task1.onResult = {
                onSuccess: (request, result) => {
                  Logger.info(`uploadPauseResumeV2_resume_:success:${JSON.stringify(result,null,2)}`)
                  expect(true).assertTrue();
                  done();
                },
                onFail: (request, error) => {
                  Logger.info(`uploadPauseResumeV2_resume_:error:${JSON.stringify(error,null,2)}`)
                  done();
                }
              }
              task1.start();
            }
          },1000);
        }
      };

      task.onResult = {
        onSuccess: (request, result) => {
          Logger.info(`uploadPauseResumeV2:success:${JSON.stringify(result,null,2)}`)
        },
        onFail: (request, error) => {
          Logger.info(`uploadPauseResumeV2:error:${JSON.stringify(error,null,2)}`)
        }
      }
      task.initCallBack = (uploadId) =>{
        _uploadId = uploadId;
      }
      task.start();
    })

    it('uploadPauseResumeV3', 0, async (done: Function) => {
      let filePath = FileUtils.getFile(20 * 1024 * 1024,'uploadPauseResumeV3');
      let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/uploadPauseResumeV3`, filePath);
      await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let task: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest);
      let _uploadId:string | undefined = undefined;
      task.onProgress = (progress: HttpProgress) => {
        Logger.info(`uploadPauseResumeV3_onProgress:${progress.complete}/${progress.target}`)
        if (progress.complete > 5 * 1024 * 1024) {
          task.pause();
          Logger.info(`uploadPauseResumeV3:pause`)
          setTimeout(async ()=>{
            Logger.info(`uploadPauseResumeV3:resume`)
            if (_uploadId) {
              putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/uploadPauseResumeV3`, filePath);
              await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
              let config = new TransferConfig();
              config.sliceLength = 2 * 1024 * 1024;
              let task1: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest,_uploadId,config);
              task1.onProgress = (progress: HttpProgress) => {
                Logger.info(`uploadPauseResumeV3_resume_onProgress:${progress.complete}/${progress.target}`)
              };
              task1.onResult = {
                onSuccess: (request, result) => {
                  Logger.info(`uploadPauseResumeV3_resume_:success:${JSON.stringify(result,null,2)}`)
                  expect(true).assertTrue();
                  done();
                },
                onFail: (request, error) => {
                  Logger.info(`uploadPauseResumeV3_resume_:error:${JSON.stringify(error,null,2)}`)
                  done();
                }
              }
              task1.start();
            }
          },1000);
        }
      };

      task.onResult = {
        onSuccess: (request, result) => {
          Logger.info(`uploadPauseResumeV3:success:${JSON.stringify(result,null,2)}`)
        },
        onFail: (request, error) => {
          Logger.info(`uploadPauseResumeV3:error:${JSON.stringify(error,null,2)}`)
        }
      }
      task.initCallBack = (uploadId) =>{
        _uploadId = uploadId;
      }
      task.start();
    })

    it('uploadCancel', 0, async (done: Function) => {
      let filePath = FileUtils.getFile(10 * 1024 * 1024,'cancel');
      let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/cancelUpload`, filePath);
      await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let task: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest);
      let cancel :boolean;
      task.onProgress = (progress: HttpProgress) => {
        if (progress.complete > 5 * 1024 * 1024 && !cancel) {
          cancel = true;
          task.cancel();
        }
      };
      task.onResult = {
        onSuccess: (request, result) => {
          done();
        },
        onFail: (request, error) => {
          Logger.info(`uploadCancel:cancel_success`)
          expect(true).assertTrue();
          done();
        }
      }
      task.start();
    })

    it('ci', 0, async (done: Function) => {
      let context = TestUtils.getContext();
      let filePath = context.filesDir + '/image.png';
      let getObjectRequest = new GetObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_PATH, filePath);
      await TestUtils.requestAddCredential(getObjectRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let downloadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).download(getObjectRequest);
      downloadTask.onResult = {
        onSuccess: async (request: GetObjectRequest, result: CosXmlDownloadTaskResult)=>{
          Logger.info(`下载成功：`)
          let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_CI_PATH, filePath);
          let picOperations: PicOperations = new PicOperations();
          picOperations.is_pic_info = 1;
          picOperations.rules.push(new PicOperationRule(TestConst.PERSIST_BUCKET_PIC_CI_JPG_PATH, "imageMogr2/format/jpg"))
          picOperations.rules.push(new PicOperationRule(TestConst.PERSIST_BUCKET_PIC_CI_ROTATE_PATH, "imageMogr2/rotate/70", "ci-auditing-sample-1253960454"))
          putRequest.setPicOperations(picOperations);
          await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
          let task: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest);
          task.onResult = {
            onSuccess: (request, result) => {
              Logger.info(`simpleUpload_success`)
              Logger.info(result)
              expect(true).assertTrue();
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
      let filePath = context.filesDir + '/6m.jpg';
      let getObjectRequest = new GetObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_6M_PATH, filePath);
      await TestUtils.requestAddCredential(getObjectRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let downloadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).download(getObjectRequest);
      downloadTask.onResult = {
        onSuccess: async (request: GetObjectRequest, result: CosXmlDownloadTaskResult)=>{
          Logger.info(`下载成功：`)
          let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, TestConst.PERSIST_BUCKET_PIC_CI_JPG_PATH, filePath);
          let picOperations: PicOperations = new PicOperations();
          picOperations.is_pic_info = 1;
          picOperations.rules.push(new PicOperationRule(TestConst.PERSIST_BUCKET_PIC_CI_PATH, "imageMogr2/format/png"))
          picOperations.rules.push(new PicOperationRule(TestConst.PERSIST_BUCKET_PIC_CI_ROTATE_PATH, "imageMogr2/rotate/70", "ci-auditing-sample-1253960454"))
          putRequest.setPicOperations(picOperations);
          await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
          let task: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest);
          task.onResult = {
            onSuccess: (request, result) => {
              Logger.info(result)
              expect(true).assertTrue();
              done();
            },
            onFail: (request, error) => {
              Logger.info(error)
              expect().assertFail()
              done();
            }
          }
          task.start();
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

    it('UploadTask_paramsCheck', 0, async (done: Function) => {
      let filePath = FileUtils.getFile(500 * 1024,'simpleUpload');
      let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/simpleFile`, filePath);
      await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let task: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest,undefined,new TransferConfig());
      task.onProgress = (progress: HttpProgress) => {
        Logger.info(`simpleUpload_onProgress：${progress.complete}/${progress.target}`)
      };
      task.onResult = {
        onSuccess: (request, result) => {
          done();
        },
        onFail: (request, error) => {
          Logger.info(error)
          expect(true).assertTrue();
          done();
        }
      }
      task.resume();
    })

    it('UploadTask_paramsCheck1', 0, async (done: Function) => {
      let filePath = FileUtils.getFile(500 * 1024,'simpleUpload');
      let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/simpleFile`, filePath);
      await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let task: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest,undefined,new TransferConfig());
      task.onProgress = (progress: HttpProgress) => {
        Logger.info(`simpleUpload_onProgress：${progress.complete}/${progress.target}`)
      };
      task.onResult = {
        onSuccess: (request, result) => {
          done();
        },
        onFail: (request, error) => {
          Logger.info(error)
          done();
        }
      }
      task.cancel();
    })

    it('UploadTask_paramsCheck2', 0, async (done: Function) => {
      let filePath = undefined;
      let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/simpleFile`, filePath);
      await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let task: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest,undefined,new TransferConfig());
      task.onProgress = (progress: HttpProgress) => {
        Logger.info(`simpleUpload_onProgress：${progress.complete}/${progress.target}`)
      };
      task.onResult = {
        onSuccess: (request, result) => {
          done();
        },
        onFail: (request, error) => {
          Logger.info(error)
          done();
        }
      }
      task.cancel();
    })

    it('UploadTask_paramsCheck3', 0, async (done: Function) => {
      let filePath = new Object() as string;
      let putRequest = new PutObjectRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/simpleFile`, filePath);
      await TestUtils.requestAddCredential(putRequest, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      let task: UploadTask = TestUtils.getCosXmlBaseService(cosXmlBaseService).upload(putRequest,undefined,new TransferConfig());
      task.onProgress = (progress: HttpProgress) => {
        Logger.info(`simpleUpload_onProgress：${progress.complete}/${progress.target}`)
      };
      task.onResult = {
        onSuccess: (request, result) => {
          done();
        },
        onFail: (request, error) => {
          Logger.info(error)
          done();
        }
      }
      task.cancel();
    })

    it('ListPartsRequest', 0, async (done: Function) => {
      let request = new ListPartsRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/simpleFile`, "test");
      request.maxParts = "1";
      request.encodingType = "1";
      request.partNumberMarker = "1";
      TestUtils.getCosXmlBaseService(cosXmlBaseService).listParts(request);
      done();
    })

    it('headObject', 0, async (done: Function) => {
      let request = new ListPartsRequest(TestConst.PERSIST_BUCKET, `uploadTest/UT/simpleFile`, "");
      request.addHeader('test','test');
      request.removeHeader('test');

      request.addQuery('test','test');
      request.removeQuery('test');

      let _set = new Set<string>();
      _set.add("aaa");
      request.addNoSignHeaderKeys(_set);
      request.addNoSignHeaderKey('')

      request.addNoSignQueryKey('')
      request.addNoSignQueryKeys(_set)
      done()
    });

  })
}