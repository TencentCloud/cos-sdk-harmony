import { CosXmlBaseService, CosXmlServiceConfig } from '../../../../Index';
import commonTest from './Common.test';
import { Credential } from './common/Credential';
import { TestConst } from './common/TestConst';
import { TestUtils } from './common/TestUtils';
import cosServiceTest from './CosService.test';
import downloadTest from './transfer/Download.test';
import uploadTest from './transfer/Upload.test';

export default function testsuite() {
  let context = TestUtils.getContext();

  // cosServiceTest(CosXmlBaseService.default());
  // uploadTest(CosXmlBaseService.default());
  // downloadTest(CosXmlBaseService.default());
  // commonTest(CosXmlBaseService.default());

  // 最终整体执行时再放开，不然单独执行某个case的时候也会执行两遍
  // 固定秘钥的cos service
  let constCredentialService = new CosXmlBaseService(
    context,
    new CosXmlServiceConfig(TestConst.PERSIST_BUCKET_REGION),
    Credential.constCredential
  )
  cosServiceTest(constCredentialService);
  uploadTest(constCredentialService);
  downloadTest(constCredentialService);
  commonTest(constCredentialService);

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