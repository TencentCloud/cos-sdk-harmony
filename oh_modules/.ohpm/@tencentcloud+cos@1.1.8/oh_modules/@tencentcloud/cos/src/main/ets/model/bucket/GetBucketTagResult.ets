import { CosXmlResult } from '../CosXmlResult';
import List from '@ohos.util.List';
import { StringUtils, XmlUtils } from '@tencentcloud/foundation';
import { CommonPrefixes, Owner } from '../../../../../Index';
import { TaggingResult } from '../object/GetObjectTagResult';

export class GetBucketTagResult extends CosXmlResult {
  tagging?: TaggingResult;

  contentParser(arrayBuffer: ArrayBuffer) {
    super.contentParser(arrayBuffer);
    if (arrayBuffer) {
      let result = XmlUtils.xml2obj(StringUtils.arrayBuffer2String(arrayBuffer))
      if (result && result['tagging']) {
        this.tagging = TaggingResult.initWithJson(result['tagging']);
      }
    }
  }
}