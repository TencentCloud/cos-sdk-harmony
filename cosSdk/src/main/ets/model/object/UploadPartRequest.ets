import { ObjectRequest } from './ObjectRequest';
import http from '@ohos.net.http';
import { RequestBodySerializer, HttpProgress, HttpResponse, RequestFileBodyWrapper,
  ContentType ,HttpHeader,
  CryptoUtil} from '@tencentcloud/foundation';
import { Callback } from '@ohos.base';
import { UploadPartResult } from './UploadPartResult';
import { CosInvalidArgumentError } from '../../error/CosInvalidArgumentError';

/**
 * 分块上传文件的方法。
 *
 * Upload Part 接口请求实现将对象按照分块的方式上传到 COS。最多支持10000分块，每个分块大小为1MB - 5GB，最后一个分块可以小于1MB。
 */
export class UploadPartRequest extends ObjectRequest {

  onHeaderReceive: Callback<Record<string, string>> | undefined;
  onProgress: Callback<HttpProgress> | undefined;
  onSuccess: Callback<HttpResponse<UploadPartResult>> | undefined;
  onFailure: Callback<Error> | undefined;

  /**
   * 标识本次分块上传的 ID；
   * 使用 Initiate Multipart Upload 接口初始化分片上传时会得到一个 uploadId，
   * 该 ID 不但唯一标识这一分块数据，也标识了这分块数据在整个文件内的相对位置
   */
  uploadId: string;
  /**
   * 标识本次分块上传的编号
   */
  partNumber: string;
  body:FilePartInfo;
  constructor(bucket: string, cosPath: string, uploadId: string,partNumber:string,body:FilePartInfo) {
    super(bucket, cosPath);
    this.uploadId = uploadId;
    this.partNumber = partNumber;
    this.body = body;
    this.isNeedMD5 = true;
  }

  public getQueries(): Map<string, string|undefined>{
    let query = super.getQueries();
    query.set("partNumber",this.partNumber)
    query.set("uploadId",this.uploadId)
    return query;
  }

  public getHeaders(): Map<string, string> {
    let headers = super.getHeaders();
    return headers
  }

  public getBodySerializer(): RequestBodySerializer|undefined {
    let serializer =  new RequestFileBodyWrapper(this.body.filePath, this.body.offset, this.body.length);
    return serializer;
  }

  public checkParameters(){
    super.checkParameters();
    if(!this.uploadId){
      throw new CosInvalidArgumentError("uploadId must not be null ");
    }
  }

  public getBody(): string | Object | ArrayBuffer | undefined {
    return this.body;
  }
  public getMethod(): http.RequestMethod {
    return http.RequestMethod.PUT;
  }
}

export class FilePartInfo {
  length:number = 0;
  offset:number = 0;
  filePath:string;
  index:number = 0;
  constructor(length:number,offset:number,filePath:string) {
    this.length = length;
    this.offset = offset;
    this.filePath = filePath;
  }
}