import { StringUtils, XmlUtils } from '@tencentcloud/foundation';
import { CosXmlResult } from '../CosXmlResult';

export class InitMultipartUploadResult extends CosXmlResult {
  initMultipartUpload: InitiateMultipartUpload|undefined;

  contentParser(arrayBuffer: ArrayBuffer){
    super.contentParser(arrayBuffer);
    if(arrayBuffer){
      let result = XmlUtils.xml2obj(StringUtils.arrayBuffer2String(arrayBuffer),true);
      if (result && result["initiateMultipartUploadResult"]) {
        this.initMultipartUpload = InitiateMultipartUpload.initWithJson(result["initiateMultipartUploadResult"]);
      }
    }
  }
}

/**
 * 初始化分块上传结果信息
 */
export class InitiateMultipartUpload{

  /**
   * 存储桶名
   */
  bucket?: string;

  /**
   * 对象的名称
   */
  key?: string;

  /**
   * 在后续上传中使用的ID
   */
  uploadId?: string;

  constructor(bucket?: string, key?: string, uploadId?: string) {
    this.bucket = bucket;
    this.key = key;
    this.uploadId = uploadId;
  }

  public static initWithJson(json:object):InitiateMultipartUpload{
    let result = new InitiateMultipartUpload();
    if (json) {
      result.bucket = json['bucket'];
      result.key = json['key'];
      result.uploadId = json['uploadId'];
    }
    return result;
  }
}