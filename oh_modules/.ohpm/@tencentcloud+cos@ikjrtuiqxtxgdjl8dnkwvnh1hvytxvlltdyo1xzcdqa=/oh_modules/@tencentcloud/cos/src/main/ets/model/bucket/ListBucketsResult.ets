import { CosXmlResult } from '../CosXmlResult';
import List from '@ohos.util.List';
import { StringUtils, XmlUtils } from '@tencentcloud/foundation';
import { Owner } from '../object/ListObjectsResult';

export class ListBucketsResult extends CosXmlResult {
  buckets: ListBuckets | undefined;

  contentParser(arrayBuffer: ArrayBuffer) {
    super.contentParser(arrayBuffer);
    if (arrayBuffer) {
      let result = XmlUtils.xml2obj(StringUtils.arrayBuffer2String(arrayBuffer))
      if (result && result['listAllMyBucketsResult']) {
        this.buckets = ListBuckets.initWithJson(result['listAllMyBucketsResult']);
      }
    }
  }
}

export class ListBuckets {
  /**
   * 存储桶持有者信息
   */
  owner?: Owner;
  /**
   * 存储桶列表
   */
  buckets?: List<Bucket>;
  /**
   * 表示本次 GetService（ListBuckets）的起点
   */
  marker?: string;
  /**
   * 是否所有的结果都已经返回。true：表示本次没有返回全部结果。false：表示本次已经返回了全部结果
   */
  isTruncated?: boolean;
  /**
   * 未返回所有结果时，作为下次 GetService 请求的 marker 参数
   */
  nextMarker?: string;

  public static initWithJson(json: object): ListBuckets {

    let result = new ListBuckets();

    let owner = Owner.initWithJson(json['owner']);
    ;
    let buckets: object = json['buckets'];
    if (buckets['bucket']) {
      buckets = buckets['bucket'];
    }
    let isTruncated: boolean = StringUtils.parseBool(json['isTruncated']);
    let marker: string = json['marker'];
    let nextMarker: string = json['nextMarker'];
    let listBuckets = new List<Bucket>();

    if (buckets) {
      if (Array.isArray(buckets) || (buckets instanceof List)) {
        for (const item of buckets as List<object>) {
          listBuckets.add(Bucket.initWithJson(item));
        }
      } else {
        listBuckets.add(Bucket.initWithJson(buckets));
      }
    }
    result.buckets = listBuckets;
    result.owner = owner;
    result.marker = marker;
    result.isTruncated = isTruncated;
    result.nextMarker = nextMarker;
    return result;
  }
}

export class Bucket {
  name?: string;
  location?: string;
  creationDate?: string;
  bucketType?: string;

  public static initWithJson(json: object): Bucket {
    let result = new Bucket();
    result.name = json['name'];
    result.location = json['location'];
    result.creationDate = json['creationDate'];
    result.bucketType = json['bucketType'];
    return result;
  }
}