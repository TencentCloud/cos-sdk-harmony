import { ObjectRequest } from './ObjectRequest';
import http from '@ohos.net.http';
import { RequestBodySerializer } from '@tencentcloud/foundation';
import { CosInvalidArgumentError } from '../../error/CosInvalidArgumentError';
import { CosXmlRequest } from '../CosXmlRequest';
import { CosXmlServiceConfig } from '../../CosXmlServiceConfig';

/**
 * 可以列出该存储桶内的部分或者全部对象。该 API 的请求者需要对存储桶有读取权限。
 *
 * 请查看 https://cloud.tencent.com/document/product/436/7734
 */
export class ListObjectsRequest extends ObjectRequest {

  /**
   * 对象键匹配前缀，限定响应中只包含指定前缀的对象键。
   */
  prefix?:string;
  /**
   * 一个字符的分隔符，用于对对象键进行分组。所有对象键中从 prefix 或从头（如未指定 prefix）到首个 delimiter 之间相同的部分将作为 CommonPrefixes 下的一个 Prefix 节点。被分组的对象键不再出现在后续对象列表中，具体场景和用法可参考下面的实际案例。
   */
  delimiter?: string;
  /**
   * 规定返回值的编码方式，可选值：url，代表返回的对象键为 URL 编码（百分号编码）后的值，例如“腾讯云”将被编码为%E8%85%BE%E8%AE%AF%E4%BA%91
   */
  encodingType?: string;
  /**
   * 起始标记，从该标记之后（不含）按照 UTF-8 字典序返回存储桶条目
   */
  marker?: string;
  /**
   * 单次返回最大的条目数量，默认值为2000，最大为2000。如果单次响应中未列出所有存储桶，COS 会返回 NextMarker 节点，其值作为下次 GetService 请求的 marker 参数
   */
  maxKeys?: number;



  constructor(bucket: string) {
    super(bucket, "");
  }

  public getQueries(): Map<string, string | undefined> {
    if (this.prefix) {
      this.addQuery('prefix',this.prefix);
    }
    if (this.delimiter) {
      this.addQuery('delimiter',this.delimiter);
    }
    if (this.encodingType) {
      this.addQuery('encoding-type',this.encodingType);
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

  public checkParameters(){
    if(!this.bucket){
      throw new CosInvalidArgumentError("bucket must not be null ");
    }
    if (this.cosPath.startsWith("/")) {
      throw new CosInvalidArgumentError("cosPath cannot start with /");
    }
  }
}







