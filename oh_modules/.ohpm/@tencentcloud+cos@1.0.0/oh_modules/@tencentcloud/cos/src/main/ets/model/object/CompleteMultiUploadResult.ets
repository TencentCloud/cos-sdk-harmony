import { CosXmlResult } from '../CosXmlResult';
import List from '@ohos.util.List';
import { PicObject } from '../pic/PicObject';
import { ImageInfo } from '../pic/ImageInfo';
import { StringUtils, XmlUtils } from '@tencentcloud/foundation';
import { PicUploadResult } from './PutObjectResult';
import { PicOriginalInfo } from '../pic/PicOriginalInfo';

export class CompleteMultiUploadResult extends CosXmlResult {
  result: CompleteMultipartUploadResult |undefined;

  contentParser(arrayBuffer: ArrayBuffer){
    super.contentParser(arrayBuffer);
    if (arrayBuffer) {
      let result = XmlUtils.xml2obj(StringUtils.arrayBuffer2String(arrayBuffer),true);
      if (result) {
        this.result = CompleteMultipartUploadResult.initWithJson(result["completeMultipartUploadResult"]);
      }
    }
  }
}

export class CompleteMultipartUploadResult{

  /**
   * 对象名
   */
  key: string|undefined;

  /**
   * 创建对象的外网访问域名
   */
  location: string|undefined;

  /**
   * 合并后文件的MD5算法校验值
   */
  eTag: string|undefined;

  imageInfo: ImageInfo|undefined;
  processResults: List<PicObject>|undefined;

  public static initWithJson(json:object):CompleteMultipartUploadResult{
    let result = new CompleteMultipartUploadResult();

    result.key = json['key'];
    result.location = json['location'];
    result.eTag = json['eTag'];

    if (json['imageInfo']) {
      result.imageInfo = ImageInfo.initWithJson(json['imageInfo']);
    }
    if (json['processResults']) {
      let processResults : List<PicObject> = new List();
      if (Array.isArray(json['processResults']) || json['processResults'] instanceof List) {
        for (const item of json['processResults'] as List<object>) {
          let item1 = PicObject.initWithJson(item);
          processResults.add(item1);
        }
      }else{
        let picObj = PicObject.initWithJson(json['processResults']);
        processResults.add(picObj)
      }
      result.processResults = processResults;
    }
    return result;
  }

  //
  // public getOriginInfo(): PicOriginalInfo {
  //   let picOriginalInfo = new PicOriginalInfo();
  //   picOriginalInfo.location = this.location;
  //   picOriginalInfo.key = this.key;
  //   picOriginalInfo.eTag = this.eTag;
  //   picOriginalInfo.imageInfo = this.imageInfo;
  //   return picOriginalInfo;
  // }
  //
  // public getPicUploadResult() : PicUploadResult{
  //   let picUploadResult = new PicUploadResult();
  //   picUploadResult.originalInfo = this.getOriginInfo();
  //   picUploadResult.processResults = this.processResults;
  //   return picUploadResult;
  // }
}