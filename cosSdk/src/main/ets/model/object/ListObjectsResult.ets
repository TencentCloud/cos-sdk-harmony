import { CosXmlResult } from '../CosXmlResult';
import List from '@ohos.util.List';
import { StringUtils, XmlUtils } from '@tencentcloud/foundation';

export class ListObjectsResult extends CosXmlResult {
  objects: ListObjects|undefined;

  contentParser(arrayBuffer: ArrayBuffer){
    super.contentParser(arrayBuffer);
    if(arrayBuffer) {
      let result = XmlUtils.xml2obj(StringUtils.arrayBuffer2String(arrayBuffer))
      if (result && result['listBucketResult']) {
        this.objects = ListObjects.initWithJson(result['listBucketResult']);
      }
    }
  }
}

export class ListObjects{

  /**
   * 存储桶的名称，格式为<BucketName-APPID>，例如examplebucket-1250000000
   */
  name?: string;

  /**
   * 编码格式，对应请求中的 encoding-type 参数，且仅当请求中指定了 encoding-type 参数才会返回该节点。
   */
  encodingType?: string;

  /**
   * 对象键匹配前缀，对应请求中的 prefix 参数。
   */
  prefix?: string;

  /**
   * 是否所有的结果都已经返回。true：表示本次没有返回全部结果。false：表示本次已经返回了全部结果
   */
  isTruncated?: boolean;

  /**
   * 单次响应返回结果的最大条目数量，对应请求中的 max-keys 参数。
   */
  maxKeys?:number;
  /**
   * 分隔符，对应请求中的 delimiter 参数，且仅当请求中指定了 delimiter 参数才会返回该节点。
   */
  delimiter?:string;
  /**
   * 起始对象键标记，从该标记之后（不含）按照 UTF-8 字典序返回对象键条目，对应请求中的 marker 参数。
   */
  marker?: string;

  /**
   * 未返回所有结果时，作为下次 GetService 请求的 marker 参数
   */
  nextMarker?: string;

  /**
   * 从 prefix 或从头（如未指定 prefix）到首个 delimiter 之间相同的部分，定义为 Common Prefix。仅当请求中指定了 delimiter 参数才有可能返回该节点。
   */
  commonPrefixes?:List<CommonPrefixes>;

  /**
   * 对象条目。
   */
  contents?:List<Content>;

  public static initWithJson(json:object):ListObjects{
    let model = new ListObjects();
    model.name = json['name'];
    model.encodingType = json['encodingType'];
    model.prefix = json['prefix'];
    model.isTruncated = StringUtils.parseBool(json['isTruncated']);
    model.maxKeys = StringUtils.parseInt(json['maxKeys']);
    model.delimiter = json['delimiter'];
    model.marker = json['marker'];
    model.nextMarker = json['nextMarker'];

    let cPrefixes:object = json['commonPrefixes'];
    let commonPrefixes = new List<CommonPrefixes>()
    if (cPrefixes){
      if (Array.isArray(cPrefixes) || (cPrefixes instanceof List)) {
        for (const item of cPrefixes as List<object>) {
          commonPrefixes.add(CommonPrefixes.initWithJson(item));
        }
      }else{
        commonPrefixes.add(CommonPrefixes.initWithJson(cPrefixes));
      }
    }
    model.commonPrefixes = commonPrefixes;

    let tempContent:object = json['contents'];
    let content = new List<Content>()
    if (tempContent){
      if (Array.isArray(tempContent) || (tempContent instanceof List)) {
        for (const item of tempContent as List<object>) {
          content.add(Content.initWithJson(item));
        }
      }else{
        content.add(Content.initWithJson(tempContent));
      }
    }
    model.contents = content;
    return model;
  }
}


export class CommonPrefixes{
  /**
   * 单条 Common Prefix 的前缀
   */
  prefix?:string;

  constructor(prefix?:string) {
    this.prefix = prefix;
  }

  public static initWithJson(json:object):CommonPrefixes{
    let result = new CommonPrefixes(json['prefix']);
    return result;
  }
}

export class Content{
  /**
   * 对象键
   */
  key?: string;

  /**
   * 对象最后修改时间，为 ISO8601 格式，例如2019-05-24T10:56:40Z
   */
  lastModified?: string;

  /**
   * 对象的实体标签（Entity Tag），是对象被创建时标识对象内容的信息标签，可用于检查对象的内容是否发生变化
   例如“8e0b617ca298a564c3331da28dcb50df”，此头部并不一定返回对象的 MD5 值，而是根据对象上传和加密方式而有所不同
   */
  eTag?: string;

  /**
   * 对象大小，单位为 Byte
   */
  size?:number;

  /**
   * 对象持有者信息
   */
  owner?:Owner;

  /**
   * 当对象存储类型为智能分层存储时，指示对象当前所处的存储层，枚举值：
   * FREQUENT（标准层）
   * INFREQUENT（低频层）
   * ARCHIVE_ACCESS（归档层）
   * DEEP_ARCHIVE_ACCESS（深度归档层）
   * 仅当 StorageClass 为 INTELLIGENT_TIERING（智能分层）时才会返回该节点
   */
  storageTier?:string;

  /**
   * 当对象存储类型为归档存储或深度归档存储时，指示对象的回热状态，支持枚举值 ONGOING、DONE、FAILED。
   * 当未向对象发起回热请求时，该字段为空。
   * 当发起回热请求后，回热进行中为 ONGING，回热已完成为 DONE，回热失败为 FAILED。
   * 仅当 StorageClass 为 ARCHIVE （归档）或 DEEP_ARCHIVE（深度归档），或 StorageClass为 NTELLIGENT_TIERING（智能分层）且 StorageTier 为ARCHIVE_ACCESS（归档层）或，DEEP_ARCHIVE_ACCESS（深度归档层）时才会返回该节点
   */
  restoreStatus?:string;

  constructor(key?:string,lastModified?:string,eTag?:string,size?:number,owner?:Owner,storageTier?:string,restoreStatus?:string) {
    this.key = key;
    this.lastModified = lastModified;
    this.eTag = eTag;
    this.size = size;
    this.owner = owner;
    this.storageTier = storageTier;
    this.restoreStatus = restoreStatus;
  }

  public static initWithJson(json:object):Content{
    let owner = Owner.initWithJson(json['owner']);
    let result = new Content(json['key'], json['lastModified'], json['eTag'],json['size'],owner,json['storageTier'],json['restoreStatus']);
    return result;
  }
}

export class Owner {
  id?: string;
  displayName?: string;

  public static initWithJson(json: object): Owner {
    let result = new Owner();
    result.id = json['iD'];
    result.displayName = json['displayName'];
    return result;
  }
}