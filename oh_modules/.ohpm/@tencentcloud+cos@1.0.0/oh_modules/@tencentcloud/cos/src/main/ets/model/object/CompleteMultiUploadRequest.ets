import { ObjectRequest } from './ObjectRequest';
import http from '@ohos.net.http';
import List from '@ohos.util.List';
import { RequestBodySerializer, XmlUtils } from '@tencentcloud/foundation';
import { ContentType } from '@tencentcloud/foundation';
import { CosInvalidArgumentError } from '../../error/CosInvalidArgumentError';

/**
 * 完成整个分块上传的方法.
 *
 * 当使用分块上传完对象的所有块以后，
 * 必须调用该接口来完成整个文件的分块上传.且在该请求的 Body 中需要给出每一个块的 PartNumber 和 ETag，用来校验块的准确性.
 * 分块上传适合于在弱网络或高带宽环境下上传较大的对象
 *
 * 关于完成整个分片上传接口的描述，请查看 https://cloud.tencent.com/document/product/436/7742
 */
export class CompleteMultiUploadRequest extends ObjectRequest {
  uploadId: string;
  completeMultipartUpload: CompleteMultipartUpload = new CompleteMultipartUpload();

  constructor(bucket: string, cosPath: string, uploadId: string) {
    super(bucket, cosPath);
    this.uploadId = uploadId;
    this.isNeedMD5 = true;
  }

  public getQueries(): Map<string, string|undefined>{
    this.addQuery("uploadId", this.uploadId);
    return this.queries;
  }

  public checkParameters(){
    super.checkParameters();
    if(!this.uploadId){
      throw new CosInvalidArgumentError("uploadId must not be null ");
    }
  }

  public getBodySerializer(): RequestBodySerializer|undefined {
    let obj:object = new Object();
    obj["completeMultipartUpload"] = this.completeMultipartUpload;
    let bodyString = XmlUtils.obj2xml(obj) || "";
    return RequestBodySerializer.wrap(ContentType.XML, bodyString);
  }
  public getMethod(): http.RequestMethod {
    return http.RequestMethod.POST;
  }
}

export class CompleteMultipartUpload{
  part: List<CompleteMultipartUploadPart> = new List();
}

export class CompleteMultipartUploadPart{
  partNumber: number;
  eTag: string;

  constructor(partNumber: number, eTag: string) {
    this.partNumber = partNumber;
    this.eTag = eTag;
  }
}