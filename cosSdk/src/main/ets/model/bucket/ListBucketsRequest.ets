import { ObjectRequest } from '../object/ObjectRequest';
import http from '@ohos.net.http';
import { RequestBodySerializer } from '@tencentcloud/foundation';
import { CosInvalidArgumentError } from '../../error/CosInvalidArgumentError';
import { CosXmlRequest } from '../CosXmlRequest';
import { CosXmlServiceConfig } from '../../CosXmlServiceConfig';

/**
 * 用来查询请求者名下的所有存储桶列表或特定地域下的存储桶列表。
 *
 * 请查看 https://cloud.tencent.com/document/product/436/8291
 */
export class ListBucketsRequest extends CosXmlRequest {

  /**
   * 支持根据地域过滤存储桶，例如 region=ap-beijing，COS 支持的地域可参考 地域和访问域名
   */
  filterRegion?: string;
  /**
   * 支持根据存储桶标签（由标签键 tagkey 和标签值 tagvalue 组成）过滤存储桶，仅支持传入一个存储桶标签，tagkey 用于传入标签键。如需根据存储桶标签查询存储桶，则 tagkey 和 tagvalue 为必填项
   */
  tagkey?: string;
  /**
   * 支持根据存储桶标签（由标签键 tagkey 和标签值 tagvalue 组成）过滤存储桶，仅支持传入一个存储桶标签，tagvalue 用于传入标签值。如需根据存储桶标签查询存储桶，则 tagkey 和 tagvalue 为必填项
   */
  tagvalue?: string;
  /**
   * GMT 时间戳，和 range 参数一起使用，支持根据创建时间过滤存储桶，例如 create-time=1642662645
   */
  createTime?: number;
  /**
   * 和 create-time 参数一起使用，支持根据创建时间过滤存储桶，支持枚举值 lt（创建时间早于 create-time）、gt（创建时间晚于 create-time）、lte（创建时间早于或等于 create-time）、gte（创建时间晚于或等于create-time）
   */
  range?: string;
  /**
   * 起始标记，从该标记之后（不含）按照 UTF-8 字典序返回存储桶条目
   */
  marker?: string;
  /**
   * 单次返回最大的条目数量，默认值为2000，最大为2000。如果单次响应中未列出所有存储桶，COS 会返回 NextMarker 节点，其值作为下次 GetService 请求的 marker 参数
   */
  maxKeys?: number;

  public getPath(cosXmlServiceConfig: CosXmlServiceConfig): string {
    return ""
  }


  constructor() {
    super();
  }

  public getQueries(): Map<string, string | undefined> {

    if (this.filterRegion){
      this.addQuery('region',this.filterRegion);
    }

    if (this.tagkey) {
      this.addQuery('tagkey',this.tagkey);
    }
    if (this.tagvalue) {
      this.addQuery('tagvalue',this.tagvalue);
    }

    if (this.createTime && this.createTime > 0) {
      this.addQuery('create-time',this.createTime.toString());
    }
    if (this.range) {
      this.addQuery('range',this.range);
    }
    if (this.marker) {
      this.addQuery('marker',this.marker);
    }
    if (this.maxKeys && this.maxKeys > 0) {
      this.addQuery('max-keys',this.maxKeys.toString());
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







