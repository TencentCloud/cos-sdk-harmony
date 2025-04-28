import { ObjectRequest } from '../object/ObjectRequest';
import http from '@ohos.net.http';
import { RequestBodySerializer } from '@tencentcloud/foundation';
import { CosInvalidArgumentError } from '../../error/CosInvalidArgumentError';
import { CosXmlRequest } from '../CosXmlRequest';
import { CosXmlServiceConfig } from '../../CosXmlServiceConfig';

/**
 * 用于拉取存储桶内的所有对象及其历史版本信息，您可以通过指定参数筛选出存储桶内部分对象及其历史版本信息。该 API 的请求者需要对存储桶有读取权限。
 *
 * 请查看 https://cloud.tencent.com/document/product/436/35521
 */
export class GetBucketObjectVersionsRequest extends CosXmlRequest {
  /**
   * 对象键匹配前缀，限定响应中只包含指定前缀的对象键。
   */
  prefix?: string;
  /**
   * 一个字符的分隔符，用于对对象键进行分组。所有对象键中从 prefix 或从头（如未指定 prefix）到首个 delimiter 之间相同的部分将作为 CommonPrefixes 下的一个 Prefix 节点。被分组的对象键不再出现在后续对象列表中，具体场景和用法可参考下面的实际案例。
   */
  delimiter?: string;
  /**
   * 规定返回值的编码方式，可选值：url，代表返回的对象键为 URL 编码（百分号编码）后的值，例如“腾讯云”将被编码为%E8%85%BE%E8%AE%AF%E4%BA%91。
   */
  encodingType?: string;
  /**
   * 起始对象键标记，从该标记之后（不含）按照 UTF-8 字典序返回对象版本条目。
   */
  keyMarker?: string;
  /**
   * 起始版本 ID 标记，从该标记之后（不含）返回对象版本条目，如果上一次 List 结果的 NextVersionIdMarker 为空，则该参数也指定为空。
   */
  versionIdMarker?: string;
  /**
   * 单次返回最大的条目数量，默认值为1000，最大为1000。
   * 注意：该参数会限制每一次 List 操作返回的最大条目数，COS 在每次 List 操作中将返回不超过 max-keys 所设定数值的条目（CommonPrefixes、Version 和 DeleteMarker 合计），
   * 如果单次响应中未列出所有对象，COS 会返回 NextKeyMarker 和 NextVersionIdMarker 节点，
   * 其值分别为您下次 List 请求的 key-marker 和 version-id-marker 参数，以便您列出后续版本。
   */
  maxKeys?: number;

  public getPath(cosXmlServiceConfig: CosXmlServiceConfig): string {
    return '';
  }

  constructor(bucket: string) {
    super();
    this.bucket = bucket;
  }

  public getQueries(): Map<string, string | undefined> {
    this.addQuery("versions", undefined);
    if (this.prefix) {
      this.addQuery('prefix', this.prefix);
    }
    if (this.delimiter) {
      this.addQuery('delimiter', this.delimiter);
    }
    if (this.encodingType) {
      this.addQuery('encoding-type', this.encodingType);
    }
    if (this.keyMarker) {
      this.addQuery('key-marker', this.keyMarker);
    }
    if (this.versionIdMarker) {
      this.addQuery('version-id-marker', this.versionIdMarker);
    }
    if (this.maxKeys && this.maxKeys > 0) {
      this.addQuery('max-keys', this.maxKeys.toString());
    }

    return this.queries;
  }


  public getBodySerializer(): RequestBodySerializer | undefined {
    return undefined;
  }

  public getMethod(): http.RequestMethod {
    return http.RequestMethod.GET;
  }
}







