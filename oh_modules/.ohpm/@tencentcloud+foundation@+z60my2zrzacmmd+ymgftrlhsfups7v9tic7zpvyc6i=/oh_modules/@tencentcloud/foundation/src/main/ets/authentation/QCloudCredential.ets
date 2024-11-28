
export class QCloudCredential {

  /**
   * 开发者拥有的项目身份识别 ID，用以身份认证
   */
  secretID?:string;

  /**
   * 开发者拥有的项目身份密钥。可以为永久密钥，也可以是临时密钥（参考CAM系统）。
   */
  secretKey?:string;

  /**
   * 签名有效期的起始时间。默认是设备的本地时间，如果传入起始时间，那么将以起始时间去计算签名。
   */
  startDate?:Date;

  /**
   * 签名有效期截止的时间。没有设置的话，默认是起始时间加30分钟。
   */
  expirationDate?:Date;

  /**
   * 当您使用了CAM系统获取临时密钥的时候，请设置改值，代表回话的ID。
   */
  token?:string;

  public valid():boolean{

    if (!this.expirationDate) {
      return true;
    }

    let date = new Date()

    // 提前60刷新
    if (date.getTime() >= this.expirationDate.getTime() - (60 * 1000)) {
      return false;
    }
    return true;
  }
}