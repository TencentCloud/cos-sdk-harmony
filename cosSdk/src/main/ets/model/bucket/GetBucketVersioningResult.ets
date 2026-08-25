import { CosXmlResult } from '../CosXmlResult';
import { StringUtils, XmlUtils } from '@tencentcloud/foundation';

/**
 * GET Bucket versioning 的返回结果。
 *
 * 响应体形如：
 * <VersioningConfiguration>
 *   <Status>Enabled</Status>
 * </VersioningConfiguration>
 *
 * 注意：当存储桶从未开启过版本控制时，COS 返回的 VersioningConfiguration 节点为空节点，
 * 此时 versioningConfiguration 或其 status 可能为 undefined，均表示未开启版本控制。
 */
export class GetBucketVersioningResult extends CosXmlResult {
  versioningConfiguration?: VersioningConfiguration;

  contentParser(arrayBuffer: ArrayBuffer) {
    super.contentParser(arrayBuffer);
    if (arrayBuffer) {
      let result = XmlUtils.xml2obj(StringUtils.arrayBuffer2String(arrayBuffer))
      if (result && result['versioningConfiguration']) {
        this.versioningConfiguration = VersioningConfiguration.initWithJson(result['versioningConfiguration']);
      }
    }
  }
}

export class VersioningConfiguration {
  /**
   * 说明版本是否开启，枚举值：Enabled、Suspended。
   * 未开启过版本控制的存储桶该值为 undefined
   */
  status?: string;

  static initWithJson(json: object): VersioningConfiguration {
    let result = new VersioningConfiguration();
    if (json) {
      result.status = json['status'];
    }
    return result;
  }
}
