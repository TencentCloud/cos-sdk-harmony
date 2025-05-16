import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import {
  CosXmlBaseService, CosXmlServiceConfig,
} from '../../../../Index';
import { GetObjectRequest } from '../../../main/ets/model/object/GetObjectRequest';
import { Credential } from './common/Credential';
import { Logger } from './common/Logger';
import { TestConst } from './common/TestConst';
import { TestUtils } from './common/TestUtils';

export default function cosRetryTest() {
  describe('cosRetryTest', () => {
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
    it('getObject500', 0, async (done: Function) => {
      let config = new CosXmlServiceConfig(TestConst.PERSIST_BUCKET_REGION);
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

    it('getObject500Noretry', 0, async (done: Function) => {
      let config = new CosXmlServiceConfig(TestConst.RETRY_BUCKET_REGION);
      config.maxRetryCount = 0;
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
  })
}