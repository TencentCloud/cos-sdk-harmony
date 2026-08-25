import { CosXmlBaseService, CosXmlServiceConfig } from '../../../../Index';
import commonTest from './Common.test';
import { Credential } from './common/Credential';
import { TestConst } from './common/TestConst';
import { TestUtils } from './common/TestUtils';
import cosRetryTest from './CosRetry.test';
import bucketTest from './Bucket.test';
import bucketModelTest from './BucketModel.test';
import cosServiceTest from './CosService.test';
import customNetworkTest from './CustomNetwork.test';
import downloadTest from './transfer/Download.test';
import transferStateTest from './transfer/TransferState.test';
import transferStateMachineTest from './transfer/TransferStateMachine.test';
import uploadTest from './transfer/Upload.test';

export default function testsuite() {
  let context = TestUtils.getContext();

  // cosServiceTest(CosXmlBaseService.default());
  // uploadTest(CosXmlBaseService.default());
  // downloadTest(CosXmlBaseService.default());
  // commonTest(CosXmlBaseService.default());

  // 最终整体执行时再放开，不然单独执行某个case的时候也会执行两遍
  // 固定秘钥的cos service
  let config = new CosXmlServiceConfig(TestConst.PERSIST_BUCKET_REGION);
  let constCredentialService = new CosXmlBaseService(
    context,
    config,
    Credential.constCredential
  )

  cosServiceTest(constCredentialService);
  // Bucket 级接口（PutBucket/DeleteBucket/Accelerate/Versioning/Location）
  bucketTest(constCredentialService);
  // Bucket 级接口的纯单元测试（序列化/反序列化，不依赖网络）
  bucketModelTest();
  uploadTest(constCredentialService);
  downloadTest(constCredentialService);
  // 传输状态回调 onState 与状态机修复
  transferStateTest(constCredentialService);
  // 传输状态机纯单元测试（updateState/markErrorIfActive/resetFailedFlag）
  transferStateMachineTest(constCredentialService);
  commonTest(constCredentialService);
  cosRetryTest();
  // 自定义网络层测试（基于 @ohos.net.http）
  customNetworkTest();

  // 最终整体执行时再放开，不然单独执行某个case的时候也会执行两遍
  // 无秘钥的cos service
  // let noCredentialService = new CosXmlBaseService(
  //   context,
  //   new CosXmlServiceConfig(TestConst.PERSIST_BUCKET_REGION)
  // )
  // cosServiceTest(noCredentialService);
  // uploadTest(noCredentialService);
  // downloadTest(noCredentialService);
}