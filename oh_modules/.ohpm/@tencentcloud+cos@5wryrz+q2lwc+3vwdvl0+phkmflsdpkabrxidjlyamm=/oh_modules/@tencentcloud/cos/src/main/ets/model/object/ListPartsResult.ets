import { CosXmlResult } from '../CosXmlResult';
import List from '@ohos.util.List';
import { StringUtils, XmlUtils } from '@tencentcloud/foundation';
import { Owner } from '../../../../../Index';

export class ListPartsResult extends CosXmlResult {
  listParts: ListParts | undefined;

  contentParser(arrayBuffer: ArrayBuffer) {
    super.contentParser(arrayBuffer);
    if (arrayBuffer) {
      let result = XmlUtils.xml2obj(StringUtils.arrayBuffer2String(arrayBuffer))
      if (result && result['listPartsResult']) {
        this.listParts = ListParts.initWithJson(result['listPartsResult']);
      }
    }
  }
}

export class ListParts {
  /**
   * 存储桶名
   */
  bucket?: string;
  /**
   * 规定返回值的编码格式
   */
  encodingType?: string;
  /**
   * 对象的名称
   */
  key?: string;
  /**
   * 标识本次分块上传的uploadId
   */
  uploadId?: string;
  /**
   * 默认以 UTF-8 二进制顺序列出条目，所有列出条目从 marker 开始
   */
  partNumberMarker?: string;
  /**
   * 用来表示这些分块的存储级别
   */
  storageClass?: string;
  /**
   * 假如返回条目被截断，则返回 NextMarker 就是下一个条目的起点
   */
  nextPartNumberMarker?: string;
  /**
   * 单次返回的最大条目数
   */
  maxParts?: string;
  /**
   * 返回条目是否被截断
   */
  isTruncated?: boolean;
  /**
   * 用来标识这些分块所有者的信息
   */
  owner?: Owner;
  /**
   * 用来标识本次上传发起者的信息
   */
  initiator?: ListPartsInitiator;
  /**
   * 用来表示每一个块的信息
   */
  public part?: List<ListPartsPart>;

  constructor(bucket?: string, encodingType?: string, key?: string, uploadId?: string, partNumberMarker?: string,
    storageClass?: string, nextPartNumberMarker?: string, maxParts?: string, isTruncated?: boolean, owner?: Owner,
    initiator?: ListPartsInitiator,
    part?: List<ListPartsPart>) {
    this.bucket = bucket;
    this.encodingType = encodingType;
    this.key = key;
    this.uploadId = uploadId;
    this.partNumberMarker = partNumberMarker;
    this.storageClass = storageClass;
    this.nextPartNumberMarker = nextPartNumberMarker;
    this.maxParts = maxParts;
    this.isTruncated = isTruncated;
    this.owner = owner;
    this.initiator = initiator;
    this.part = part;
  }

  public setPart(part: List<ListPartsPart>) {
    this.part = part;
  }

  public static initWithJson(json: object): ListParts {
    let result = new ListParts();
    if (json) {
      let bucket: string = json['bucket'];
      let encodingType: string = json['encodingType'];
      let key: string = json['key'];
      let uploadId: string = json['uploadId'];
      let partNumberMarker: string = json['partNumberMarker'];
      let storageClass: string = json['storageClass'];
      let nextPartNumberMarker: string = json['nextPartNumberMarker'];
      let maxParts: string = json['maxParts'];
      let isTruncated: boolean = StringUtils.parseBool(json['isTruncated']);
      let owner = Owner.initWithJson(json['owner']);
      ;
      let initiator = ListPartsInitiator.initWithJson(json['initiator']);
      let part: object = json['part'];
      let list = new List<ListPartsPart>();

      if (part) {
        if (Array.isArray(part) || (part instanceof List)) {
          for (const item of part as List<object>) {
            list.add(ListPartsPart.initWithJson(item));
          }
        } else {
          list.add(ListPartsPart.initWithJson(part));
        }
      }
      result.bucket = bucket;
      result.encodingType = encodingType;
      result.key = key;
      result.uploadId = uploadId;
      result.partNumberMarker = partNumberMarker;
      result.storageClass = storageClass;
      result.nextPartNumberMarker = nextPartNumberMarker;
      result.maxParts = maxParts;
      result.isTruncated = isTruncated;
      result.owner = owner;
      result.initiator = initiator;
      result.part = list;
    }

    return result;
  }
}

export class ListPartsInitiator {
  id?: string;
  displayName?: string;

  constructor(id?: string, displayName?: string) {
    this.id = id;
    this.displayName = displayName;
  }

  public static initWithJson(json: object): ListPartsInitiator | undefined {
    let result = new ListPartsInitiator();
    if (json) {
      result.id = json['iD'];
      result.displayName = json['displayName'];
    }
    return result;
  }
}

export class ListPartsPart {
  partNumber: string;
  lastModified: string;
  eTag: string;
  size: string;

  constructor(partNumber: string, lastModified: string, eTag: string, size: string) {
    this.partNumber = partNumber;
    this.lastModified = lastModified;
    this.eTag = eTag;
    this.size = size;
  }

  public static initWithJson(json: object): ListPartsPart {
    let result = new ListPartsPart(json['partNumber'], json['lastModified'], json['eTag'], json['size']);
    return result;
  }
}