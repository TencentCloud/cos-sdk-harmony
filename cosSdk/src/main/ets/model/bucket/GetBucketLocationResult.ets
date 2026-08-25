import { CosXmlResult } from '../CosXmlResult';
import { StringUtils, XmlUtils } from '@tencentcloud/foundation';

/**
 * GET Bucket location 的返回结果。
 *
 * 响应体形如：
 * <LocationConstraint>ap-guangzhou</LocationConstraint>
 *
 * 该 XML 的根节点直接就是文本值，没有嵌套子节点。
 * XmlUtils.xml2obj 对这种「根节点下只有文本节点」的结构会返回 { locationConstraint: 'ap-guangzhou' }，
 * 即 result['locationConstraint'] 直接是字符串而非对象，因此这里直接取值。
 */
export class GetBucketLocationResult extends CosXmlResult {
  /**
   * 存储桶所在地域，例如 ap-guangzhou、ap-beijing、eu-frankfurt 等
   */
  location?: string;

  contentParser(arrayBuffer: ArrayBuffer) {
    super.contentParser(arrayBuffer);
    if (arrayBuffer) {
      let result = XmlUtils.xml2obj(StringUtils.arrayBuffer2String(arrayBuffer))
      if (result && result['locationConstraint']) {
        this.location = result['locationConstraint'];
      }
    }
  }
}
