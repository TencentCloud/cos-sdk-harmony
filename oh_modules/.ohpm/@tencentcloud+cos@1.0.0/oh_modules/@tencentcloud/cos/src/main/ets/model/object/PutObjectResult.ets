import { CosXmlResult } from '../CosXmlResult';
import List from '@ohos.util.List';
import { PicObject } from '../pic/PicObject';
import { PicOriginalInfo } from '../pic/PicOriginalInfo';
import { HttpHeader, StringUtils, XmlUtils } from '@tencentcloud/foundation';

export class PutObjectResult extends CosXmlResult {
  public picUploadResult: PicUploadResult|undefined;

  contentParser(arrayBuffer: ArrayBuffer){
    super.contentParser(arrayBuffer);
    if (arrayBuffer) {
      let result = XmlUtils.xml2obj(StringUtils.arrayBuffer2String(arrayBuffer),true);
      if (result && result["uploadResult"]) {
        this.picUploadResult = PicUploadResult.initWithJson(result["uploadResult"]);
      }
    }
  }

  eTag(): string|undefined {
    if(this.headers){
      return this.headers[HttpHeader.ETAG];
    }
    return undefined;
  }
}

export class PicUploadResult {
  public originalInfo: PicOriginalInfo|undefined;
  public processResults: List<PicObject>|undefined;

  public static initWithJson(json:object):PicUploadResult{
    let result = new PicUploadResult();
    if (json['originalInfo']) {
      result.originalInfo = PicOriginalInfo.initWithJson(json['originalInfo']);
    }
    if (json['processResults']) {

      let processResults : List<PicObject> = new List();
      if (Array.isArray(json['processResults']) || json['processResults'] instanceof List) {
        for (const item of json['processResults'] as List<object>) {
          let item1 = PicObject.initWithJson(item);
          processResults.add(item1);
        }
      }else{
        let picObj:PicObject = PicObject.initWithJson(json['processResults']);
        processResults.add(picObj)
      }
      result.processResults = processResults;
    }
    return result;
  }
}