import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { CosXmlBaseService, CosXmlServiceConfig, QCloudCredential,QCloudLogger } from '@tencentcloud/cos';
import { Credential } from '../Credential';
import { Const, CredentialType } from '../Const';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
    CosXmlBaseService.setDebuggable(true);
    // QCloudLogger.logOutputCallback = (log)=>{
    //   console.log("logOutputCallback" + log);
    // }
    if(Const.CREDENTIAL_TYPE === CredentialType.STS){
      // 临时密钥
      CosXmlBaseService.initDefaultService(
        this.context.getApplicationContext(),
        new CosXmlServiceConfig(Const.TEST_BUCKET_REGION),
        Credential.sessionCredential
      )
      new CosXmlBaseService(this.context.getApplicationContext(),new CosXmlServiceConfig(Const.TEST_BUCKET_REGION),Credential.sessionCredential)
    } else if(Const.CREDENTIAL_TYPE === CredentialType.CONST) {
      // 固定密钥
      let config = new CosXmlServiceConfig(Const.TEST_BUCKET_REGION);
      config.retrySleep = 5 * 1000;
      // config.readTimeout = 30 * 1000 * 1000;
      CosXmlBaseService.initDefaultService(
        this.context.getApplicationContext(),
        config,
        Credential.constCredential
      )
    } else {
      // 无密钥（单独给request设置密钥或者匿名模式）
      CosXmlBaseService.initDefaultService(
        this.context.getApplicationContext(),
        new CosXmlServiceConfig(Const.TEST_BUCKET_REGION)
      )
    }
  }


  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/root_page/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
