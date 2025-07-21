import { CosXmlResult } from '../CosXmlResult';
import List from '@ohos.util.List';
import { StringUtils, XmlUtils } from '@tencentcloud/foundation';
import { CommonPrefixes, Owner } from '../../../../../Index';

export class GetBucketObjectVersionsResult extends CosXmlResult {
  listVersionsResult: ListVersionsResult | undefined;

  contentParser(arrayBuffer: ArrayBuffer) {
    super.contentParser(arrayBuffer);
    if (arrayBuffer) {
      let result = XmlUtils.xml2obj(StringUtils.arrayBuffer2String(arrayBuffer))
      if (result && result['listVersionsResult']) {
        this.listVersionsResult = ListVersionsResult.initWithJson(result['listVersionsResult']);
      }
    }
  }
}

export class ListVersionsResult {
  /**
   * 编码格式，对应请求中的 encoding-type 参数，且仅当请求中指定了 encoding-type 参数才会返回该节点
   */
  encodingType?: string;
  /**
   *  存储桶的名称，格式为<BucketName-APPID>，例如examplebucket-1250000000
   */
  name?: string;
  /**
   *  对象键匹配前缀，对应请求中的 prefix 参数
   */
  prefix?: string;
  /**
   *  起始对象键标记，从该标记之后（不含）按照 UTF-8 字典序返回对象版本条目，对应请求中的 key-marker 参数
   */
  keyMarker?: string;
  /**
   *  起始版本 ID 标记，从该标记之后（不含）返回对象版本条目，对应请求中的 version-id-marker 参数
   */
  versionIdMarker?: string;
  /**
   *  单次响应返回结果的最大条目数量，对应请求中的 max-keys 参数
   */
  maxKeys?: number;
  /**
   *  响应条目是否被截断，布尔值，例如 true 或 false
   */
  isTruncated?: boolean;
  /**
   *  仅当响应条目有截断（IsTruncated 为 true）才会返回该节点，该节点的值为当前响应条目中的最后一个对象键，当需要继续请求后续条目时，将该节点的值作为下一次请求的 key-marker 参数传入
   */
  nextKeyMarker?: string;
  /**
   *  仅当响应条目有截断（IsTruncated 为 true）才会返回该节点，该节点的值为当前响应条目中的最后一个对象的版本 ID，当需要继续请求后续条目时，将该节点的值作为下一次请求的 version-id-marker 参数传入。该节点的值可能为空，此时下一次请求的 version-id-marker 参数也需要指定为空。
   */
  nextVersionIdMarker?: string;
  /**
   *  分隔符，对应请求中的 delimiter 参数，且仅当请求中指定了 delimiter 参数才会返回该节点
   */
  delimiter?: string;
  /**
   *  从 prefix 或从头（如未指定 prefix）到首个 delimiter 之间相同的部分，定义为 Common Prefix。仅当请求中指定了 delimiter 参数才有可能返回该节点
   */
  commonPrefixes?: List<CommonPrefixes>;
  /**
   *  对象版本条目
   */
  version?: List<Version>;
  /**
   *  对象删除标记条目
   */
  deleteMarker?: List<DeleteMarker>;

  public static initWithJson(json: object): ListVersionsResult {
    let result = new ListVersionsResult();
    if (json) {

      result.encodingType = json['encodingType']
      result.name = json['name']
      result.prefix = json['prefix']
      result.keyMarker = json['keyMarker']
      result.versionIdMarker = json['versionIdMarker']
      result.maxKeys = StringUtils.parseInt(json['maxKeys'])
      result.isTruncated = StringUtils.parseBool(json['isTruncated'])
      result.nextKeyMarker = json['nextKeyMarker']
      result.nextVersionIdMarker = json['nextVersionIdMarker']
      result.delimiter = json['delimiter']

      let cPrefixes: object = json['commonPrefixes'];
      let commonPrefixes = new List<CommonPrefixes>()
      if (cPrefixes) {
        if (Array.isArray(cPrefixes) || (cPrefixes instanceof List)) {
          for (const item of cPrefixes as List<object>) {
            commonPrefixes.add(CommonPrefixes.initWithJson(item));
          }
        } else {
          commonPrefixes.add(CommonPrefixes.initWithJson(cPrefixes));
        }
      }
      result.commonPrefixes = commonPrefixes;

      let tVersion: object = json['version'];
      let version = new List<Version>()
      if (tVersion) {
        if (Array.isArray(tVersion) || (tVersion instanceof List)) {
          for (const item of tVersion as List<object>) {
            version.add(Version.initWithJson(item));
          }
        } else {
          version.add(Version.initWithJson(cPrefixes));
        }
      }
      result.version = version;

      let tDeleteMarker: object = json['deleteMarker'];
      let deleteMarker = new List<DeleteMarker>()
      if (tDeleteMarker) {
        if (Array.isArray(tDeleteMarker) || (tDeleteMarker instanceof List)) {
          for (const item of tDeleteMarker as List<object>) {
            deleteMarker.add(DeleteMarker.initWithJson(item));
          }
        } else {
          deleteMarker.add(DeleteMarker.initWithJson(tDeleteMarker));
        }
      }
      result.deleteMarker = deleteMarker;
    }
    return result;
  }
}

export class Version {
  /**
   * 对象键
   */
  key?: string;
  /**
   * 对象的版本 ID
   * 当未启用版本控制时，该节点的值为空字符串
   * 当启用版本控制时，启用版本控制之前的对象，其版本 ID 为 null
   * 当暂停版本控制时，新上传的对象其版本 ID 为 null，且同一个对象最多只存在一个版本 ID 为 null 的对象版本
   */
  versionId?: string;
  /**
   * 当前版本是否为该对象的最新版本
   */
  isLatest?: boolean;
  /**
   * 当前版本的最后修改时间，为 ISO8601 格式，例如2019-05-24T10:56:40Z
   */
  lastModified?: string;
  /**
   * 对象的实体标签（Entity Tag），是对象被创建时标识对象内容的信息标签，可用于检查对象的内容是否发生变化
   * 例如"8e0b617ca298a564c3331da28dcb50df"。此头部并不一定返回对象的 MD5 值，而是根据对象上传和加密方式而有所不同
   */
  eTag?: string;
  /**
   * 对象大小，单位为 Byte
   */
  size?: number;
  /**
   * 对象存储类型。枚举值请参见 存储类型 文档，例如 STANDARD_IA，ARCHIVE
   */
  storageClass?: string;
  /**
   * 当对象存储类型为智能分层存储时，指示对象当前所处的存储层，枚举值：FREQUENT（标准层），INFREQUENT（低频层）。仅当 StorageClass 为 INTELLIGENT_TIERING（智能分层）时才会返回该节点
   */
  storageTier?: string;
  /**
   * 对象持有者信息
   */
  owner?: Owner;

  public static initWithJson(json: object): Version {
    let result = new Version();
    if (json) {
      result.key = json['key'];
      result.versionId = json['versionId'];
      result.isLatest = StringUtils.parseBool(json['isLatest']);
      result.lastModified = json['lastModified'];
      result.eTag = json['eTag'];
      result.size = StringUtils.parseInt(json['size']);
      result.storageClass = json['storageClass'];
      result.storageTier = json['storageTier'];
      if (json['owner']) {
        result.owner = Owner.initWithJson(json['owner']);
      }
    }
    return result;
  }
}

export class DeleteMarker {
  /**
   * 对象键
   */
  key?: string;
  /**
   * 对象的删除标记的版本 ID
   */
  versionId?: string;
  /**
   * 当前删除标记是否为该对象的最新版本
   */
  isLatest?: boolean;
  /**
   * 当前删除标记的删除时间，为 ISO8601 格式，例如2019-05-24T10:56:40Z
   */
  lastModified?: string;
  /**
   * 对象持有者信息
   */
  owner?: Owner;

  public static initWithJson(json: object): DeleteMarker {
    let result = new DeleteMarker();
    if (json) {
      result.key = json['key'];
      result.versionId = json['versionId'];
      result.isLatest = StringUtils.parseBool(json['isLatest']);
      result.lastModified = json['lastModified'];
      if (json['owner']) {
        result.owner = Owner.initWithJson(json['owner']);
      }
    }
    return result;
  }
}