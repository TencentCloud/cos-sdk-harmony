import { ObjectRequest } from './ObjectRequest';
import http from '@ohos.net.http';
import { RequestBodySerializer } from '@tencentcloud/foundation';
import { CosInvalidArgumentError } from '../../error/CosInvalidArgumentError';

/**
 * 查询特定分块上传中的已上传的块的方法.
 *
 * COS 支持查询特定分块上传中的已上传的块, 即可以 罗列出指定 UploadId 所属的所有已上传成功的分块.
 * 因此，基于此可以完成续传功能.
 *
 * 关于查询特定分块上传中的已上传块接口的描述，请查看 https://cloud.tencent.com/document/product/436/7747
 */
export class ListPartsRequest extends ObjectRequest {

  /**
   * 标识本次分块上传的uploadId
   */
  uploadId: string;
  maxParts: string|undefined;
  /**
   * 默认以 UTF-8 二进制顺序列出条目，所有列出条目从 marker 开始
   */
  partNumberMarker: string|undefined;

  /**
   * 规定返回值的编码方式
   */
  encodingType: string|undefined;

  constructor(bucket: string, cosPath: string, uploadId: string) {
    super(bucket, cosPath);
    this.uploadId = uploadId;
  }

  public getQueries(): Map<string, string|undefined>{
    this.addQuery("uploadId", this.uploadId);
    if(this.maxParts){
      this.addQuery("max-parts", this.maxParts);
    }
    if(this.partNumberMarker){
      this.addQuery("part-number-marker", this.partNumberMarker);
    }
    if(this.encodingType){
      this.addQuery("encoding-type", this.encodingType);
    }
    return this.queries;
  }

  public checkParameters(){
    super.checkParameters();
    if(!this.uploadId){
      throw new CosInvalidArgumentError("uploadId must not be null ");
    }
  }

  public getBodySerializer(): RequestBodySerializer|undefined {
    return undefined;
  }
  public getMethod(): http.RequestMethod {
    return http.RequestMethod.GET;
  }
}