export const ksimpleUploadLimit :number = 1 * 1024 * 1024;
export const kSliceLength :number = 1 * 1024 * 1024;
export const kMD5Length:number = 32;
export const kSha1Length:number = 40;

export class TransferConfig {

  /**
   * 简单上传限制
   * 文件大小小于该值，使用简单上传。大于等于则使用分块上传
   */
  simpleUploadLimit:number = ksimpleUploadLimit;

  /**
   * 分块大小
   * 分块上传时，每个分块大小。最小为1m
   */
  sliceLength:number = kSliceLength;

  md5Length:number = kMD5Length;

  sha1Length:number = kSha1Length;
}