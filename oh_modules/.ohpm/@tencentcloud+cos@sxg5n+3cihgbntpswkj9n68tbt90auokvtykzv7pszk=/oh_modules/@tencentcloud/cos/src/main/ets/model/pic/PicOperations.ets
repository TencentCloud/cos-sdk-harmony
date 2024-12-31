/**
 * 万象图片参数
 */
import List from '@ohos.util.List';

export class PicOperations {
  /**
   * 是否返回原图信息，0不返回原图信息，1返回原图信息，默认为0。
   */
  public is_pic_info: number = 0;
  /**
   * 处理规则，一条规则对应一个处理结果（目前支持五条规则），不填则不进行图片处理。
   */
  public rules: PicOperationRule[] = [];
}

/**
 * 万象图片参数-处理规则
 */
export class PicOperationRule {
  /**
   * 处理后文件的保存路径及名称。
   当 fileid 与 ObjectKey 相同时，处理后的文件将覆盖原文件存储；不相同时将分别存储原文件和处理后文件。名称规则说明：
   1. 名称需要经过URLEncode。
   2. 以 / 开头为绝对路径，例如 fileid 值为 /p2/test2.jpg 时，表示在 p2 文件夹中存储了一个文件名为 test2.jpg 的文件。
   3. 不以 / 开头为相对路径，例如 fileid 值为 p2/test2.jpg 时，表示在 p1 文件夹中新建了一个 p2 文件夹，然后在 p2 文件夹中存储了一个文件名为 test2.jpg 的文件。
   4. 注意：请不要以 / 结尾，否则会产生空文件名。
   */
  public fileid: string;
  /**
   * 图片处理参数，若按指定样式处理，则以 style/ 开头，后加样式名，如样式名为 test，则 rule 字段为 style/test, https://cloud.tencent.com/document/product/460/6924
   */
  public rule: string;
  /**
   * 存储结果的目标存储桶名称，格式为 BucketName-APPID，如果不指定的话默认保存到当前存储桶。
   */
  public bucket?: string;

  /**
   * 万象图片参数-处理规则
   * @param fileid 处理后文件的保存路径及名称
   * @param rule 图片处理参数，若按指定样式处理，则以 style/ 开头，后加样式名，如样式名为 test，则 rule 字段为 style/test
   * @param bucket 存储结果的目标存储桶名称，格式为 BucketName-APPID，如果不指定的话默认保存到当前存储桶
   */
  constructor(fileid: string, rule: string, bucket?: string) {
    this.fileid = fileid;
    this.rule = rule;
    this.bucket = bucket;
  }

}