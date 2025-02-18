import { CosXmlResult } from '../CosXmlResult';
import List from '@ohos.util.List';
import { StringUtils, XmlUtils } from '@tencentcloud/foundation';

export class GetObjectTagResult extends CosXmlResult {
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

export class TaggingResult {
  /**
   * 标签集合
   */
  tagSet?: List<TagResult>;

  static initWithJson(json: object): TaggingResult {
    let result = new TaggingResult();
    if (json) {
      let tTagSet: object = json['tagSet'];
      if (tTagSet) {
        tTagSet = tTagSet['tag'];
      }
      let tagSet = new List<TagResult>();

      if (tTagSet) {
        if (Array.isArray(tTagSet) || (tTagSet instanceof List)) {
          for (const item of tTagSet as List<object>) {
            tagSet.add(TagResult.initWithJson(item));
          }
        } else {
          tagSet.add(TagResult.initWithJson(tTagSet));
        }
      }
      result.tagSet = tagSet;
    }
    return result;
  }
}

export class TagResult {
  /**
   * 标签的 Key，不可为空，长度小于128字节, 支持英文字母、数字、空格、加号、减号、下划线、等号、点号、冒号、斜线
   */
  key?: string;
  /**
   * 标签的 Value，长度小于256字节, 支持英文字母、数字、空格、加号、减号、下划线、等号、点号、冒号、斜线
   */
  value?: string;

  static initWithJson(json: object): TagResult {
    let result = new TagResult();
    if (json) {
      result.key = json['key'];
      result.value = json['value'];
    }
    return result;
  }
}