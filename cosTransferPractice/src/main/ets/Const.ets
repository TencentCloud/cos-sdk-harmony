/**
 * 常量配置
 * 请替换为您自己的业务配置
 */
export enum CredentialType {
  STS,
  CONST
}

export class Const {
  public static readonly CREDENTIAL_TYPE: CredentialType = CredentialType.STS;// 临时密钥STS和固定密钥CONST
  public static readonly STS_CREDENTIAL_URL = "http://x.x.x.x:3000/sts";
  public static readonly CONST_SECRET_ID = "XXXXXXXXXXXXXXXXXXXXXXX";
  public static readonly CONST_SECRET_KEY = "XXXXXXXXXXXXXXXXXXXXXXX";

  public static readonly TEST_BUCKET_REGION = "ap-guangzhou";
  public static readonly TEST_BUCKET = "mobile-ut-1253960454";
  public static readonly TEST_UPLOAD_DIR = "uploadTest/";
  public static readonly TEST_DOWNLOAD_PATH = "do_not_remove/video.mp4";
}