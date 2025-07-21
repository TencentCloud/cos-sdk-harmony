import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import {
  CosXmlBaseService, CosXmlServiceConfig,
} from '../../../../Index';
import { GetObjectRequest } from '../../../main/ets/model/object/GetObjectRequest';
import { Credential } from './common/Credential';
import { Logger } from './common/Logger';
import { TestConst } from './common/TestConst';
import { TestUtils } from './common/TestUtils';

export default function cosRetryTest2() {
  describe('cosRetryTest2', () => {
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
    it('500', 0, async (done: Function) => {
      let config = new CosXmlServiceConfig(TestConst.RETRY_BUCKET_REGION);
      config.disableBackupHost = true;
      let cosXmlBaseService = new CosXmlBaseService(
        TestUtils.getContext(),
        config,
        Credential.constCredential
      )

      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request =
        new GetObjectRequest(TestConst.RETRY_BUCKET, "500",  filesDir + '/500');
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).getObject(request)
        Logger.info(result)
        if (result.httpCode && result.httpCode >= 200 && result.httpCode <= 300) {
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

    it('503', 0, async (done: Function) => {
      let config = new CosXmlServiceConfig(TestConst.RETRY_BUCKET_REGION);
      config.disableBackupHost = true;
      let cosXmlBaseService = new CosXmlBaseService(
        TestUtils.getContext(),
        config,
        Credential.constCredential
      )

      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request =
        new GetObjectRequest(TestConst.RETRY_BUCKET, "503",  filesDir + '/503');
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).getObject(request)
        Logger.info(result)
        if (result.httpCode && result.httpCode >= 200 && result.httpCode <= 300) {
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
    it('504', 0, async (done: Function) => {
      let config = new CosXmlServiceConfig(TestConst.RETRY_BUCKET_REGION);
      config.disableBackupHost = true;
      let cosXmlBaseService = new CosXmlBaseService(
        TestUtils.getContext(),
        config,
        Credential.constCredential
      )

      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request =
        new GetObjectRequest(TestConst.RETRY_BUCKET, "504",  filesDir + '/504');
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).getObject(request)
        Logger.info(result)
        if (result.httpCode && result.httpCode >= 200 && result.httpCode <= 300) {
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

    it('404', 0, async (done: Function) => {
      let config = new CosXmlServiceConfig(TestConst.RETRY_BUCKET_REGION);
      config.disableBackupHost = true;
      let cosXmlBaseService = new CosXmlBaseService(
        TestUtils.getContext(),
        config,
        Credential.constCredential
      )

      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request =
        new GetObjectRequest(TestConst.RETRY_BUCKET, "404",  filesDir + '/404');
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).getObject(request)
        expect(result.httpCode === 404).assertTrue();
      } catch (e) {
        TestUtils.printError(e);
        expect(e!== undefined).assertTrue();
      }
      done();
    })

    it('403', 0, async (done: Function) => {
      let config = new CosXmlServiceConfig(TestConst.RETRY_BUCKET_REGION);
      config.disableBackupHost = true;
      let cosXmlBaseService = new CosXmlBaseService(
        TestUtils.getContext(),
        config,
        Credential.constCredential
      )

      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request =
        new GetObjectRequest(TestConst.RETRY_BUCKET, "403",  filesDir + '/403');
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).getObject(request)
        expect(result.httpCode === 403).assertTrue();
      } catch (e) {
        TestUtils.printError(e);
        expect(e!== undefined).assertTrue();
      }
      done();
    })

    it('400', 0, async (done: Function) => {
      let config = new CosXmlServiceConfig(TestConst.RETRY_BUCKET_REGION);
      config.disableBackupHost = true;
      let cosXmlBaseService = new CosXmlBaseService(
        TestUtils.getContext(),
        config,
        Credential.constCredential
      )

      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request =
        new GetObjectRequest(TestConst.RETRY_BUCKET, "400",  filesDir + '/400');
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).getObject(request)
        expect(result.httpCode === 400).assertTrue();
      } catch (e) {
        TestUtils.printError(e);
        expect(e!== undefined).assertTrue();
      }
      done();
    })

    it('301', 0, async (done: Function) => {
      let config = new CosXmlServiceConfig(TestConst.RETRY_BUCKET_REGION);
      config.disableBackupHost = true;
      let cosXmlBaseService = new CosXmlBaseService(
        TestUtils.getContext(),
        config,
        Credential.constCredential
      )

      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request =
        new GetObjectRequest(TestConst.RETRY_BUCKET, "301",  filesDir + '/301');
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).getObject(request)
        if (result.httpCode && result.httpCode >= 200 && result.httpCode <= 300) {
          expect(true).assertTrue();
        } else {
          expect().assertFail();
        }
      } catch (e) {
        TestUtils.printError(e);
        expect(e!== undefined).assertTrue();
      }
      done();
    })

    it('302', 0, async (done: Function) => {
      let config = new CosXmlServiceConfig(TestConst.RETRY_BUCKET_REGION);
      config.disableBackupHost = true;
      let cosXmlBaseService = new CosXmlBaseService(
        TestUtils.getContext(),
        config,
        Credential.constCredential
      )

      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request =
        new GetObjectRequest(TestConst.RETRY_BUCKET, "302",  filesDir + '/302');
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).getObject(request)
        if (result.httpCode && result.httpCode >= 200 && result.httpCode <= 300) {
          expect(true).assertTrue();
        } else {
          expect().assertFail();
        }
      } catch (e) {
        TestUtils.printError(e);
        expect(e!== undefined).assertTrue();
      }
      done();
    })

    it('200', 0, async (done: Function) => {
      let config = new CosXmlServiceConfig(TestConst.RETRY_BUCKET_REGION);
      config.disableBackupHost = true;
      let cosXmlBaseService = new CosXmlBaseService(
        TestUtils.getContext(),
        config,
        Credential.constCredential
      )

      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request =
        new GetObjectRequest(TestConst.RETRY_BUCKET, "200",  filesDir + '/200');
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).getObject(request)
        if (result.httpCode && result.httpCode >= 200 && result.httpCode <= 300) {
          expect(true).assertTrue();
        } else {
          expect().assertFail();
        }
      } catch (e) {
        TestUtils.printError(e);
        expect(e!== undefined).assertTrue();
      }
      done();
    })

    it('204', 0, async (done: Function) => {
      let config = new CosXmlServiceConfig(TestConst.RETRY_BUCKET_REGION);
      config.disableBackupHost = true;
      let cosXmlBaseService = new CosXmlBaseService(
        TestUtils.getContext(),
        config,
        Credential.constCredential
      )

      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request =
        new GetObjectRequest(TestConst.RETRY_BUCKET, "204",  filesDir + '/204');
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).getObject(request)
        if (result.httpCode && result.httpCode >= 200 && result.httpCode <= 300) {
          expect(true).assertTrue();
        } else {
          expect().assertFail();
        }
      } catch (e) {
        TestUtils.printError(e);
        expect(e!== undefined).assertTrue();
      }
      done();
    })

    it('206', 0, async (done: Function) => {
      let config = new CosXmlServiceConfig(TestConst.RETRY_BUCKET_REGION);
      config.disableBackupHost = true;
      let cosXmlBaseService = new CosXmlBaseService(
        TestUtils.getContext(),
        config,
        Credential.constCredential
      )

      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request =
        new GetObjectRequest(TestConst.RETRY_BUCKET, "206",  filesDir + '/206');
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).getObject(request)
        if (result.httpCode && result.httpCode >= 200 && result.httpCode <= 300) {
          expect(true).assertTrue();
        } else {
          expect().assertFail();
        }
      } catch (e) {
        TestUtils.printError(e);
        expect(e!== undefined).assertTrue();
      }
      done();
    })


    it('shutdown', 0, async (done: Function) => {
      let config = new CosXmlServiceConfig(TestConst.RETRY_BUCKET_REGION);
      config.disableBackupHost = true;
      let cosXmlBaseService = new CosXmlBaseService(
        TestUtils.getContext(),
        config,
        Credential.constCredential
      )

      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request =
        new GetObjectRequest(TestConst.RETRY_BUCKET, "shutdown",  filesDir + '/shutdown');
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).getObject(request)
        Logger.info(result)
        if (result.httpCode && result.httpCode >= 200 && result.httpCode <= 300) {
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

    it('timeout', 0, async (done: Function) => {
      let config = new CosXmlServiceConfig(TestConst.RETRY_BUCKET_REGION);
      config.disableBackupHost = true;
      let cosXmlBaseService = new CosXmlBaseService(
        TestUtils.getContext(),
        config,
        Credential.constCredential
      )

      let context = TestUtils.getContext();
      let filesDir = context.filesDir;
      let request =
        new GetObjectRequest(TestConst.RETRY_BUCKET, "timeout",  filesDir + '/timeout');
      await TestUtils.requestAddCredential(request, TestUtils.getCosXmlBaseService(cosXmlBaseService));
      try {
        let result = await TestUtils.getCosXmlBaseService(cosXmlBaseService).getObject(request)
        Logger.info(result)
        if (result.httpCode && result.httpCode >= 200 && result.httpCode <= 300) {
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
  })
}