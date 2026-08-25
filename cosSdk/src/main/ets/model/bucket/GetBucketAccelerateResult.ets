import { CosXmlResult } from '../CosXmlResult';
import { StringUtils, XmlUtils } from '@tencentcloud/foundation';

/**
 * GET Bucket accelerate 的返回结果。
 *
 * 响应体形如：
 * <AccelerateConfiguration>
 *   <Status>Enabled</Status>
 *   <Type>COS</Type>
 * </AccelerateConfiguration>
 *
 * 注意：当存储桶从未配置过全球加速时，COS 返回的 AccelerateConfiguration 节点为空节点，
 * 此时 accelerateConfiguration 或其 status 可能为 undefined。
 */
export class GetBucketAccelerateResult extends CosXmlResult {
  accelerateConfiguration?: AccelerateConfiguration;

  contentParser(arrayBuffer: ArrayBuffer) {
    super.contentParser(arrayBuffer);
    if (arrayBuffer) {
      let result = XmlUtils.xml2obj(StringUtils.arrayBuffer2String(arrayBuffer))
      if (result && result['accelerateConfiguration']) {
        this.accelerateConfiguration = AccelerateConfiguration.initWithJson(result['accelerateConfiguration']);
      }
    }
  }
}

export class AccelerateConfiguration {
  /**
   * 说明全球加速功能是否开启，枚举值：Enabled、Suspended
   */
  status?: string;
  /**
   * 加速类型，目前仅支持 COS
   */
  type?: string;

  static initWithJson(json: object): AccelerateConfiguration {
    let result = new AccelerateConfiguration();
    if (json) {
      result.status = json['status'];
      result.type = json['type'];
    }
    return result;
  }
}
