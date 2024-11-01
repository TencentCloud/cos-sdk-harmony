import { ObjectRequest } from './ObjectRequest';
import http from '@ohos.net.http';
import { RequestBodySerializer } from '@tencentcloud/foundation';
import { CosInvalidArgumentError } from '../../error/CosInvalidArgumentError';

/**
 * 舍弃一个分块上传且删除已上传的分片块的方法.
 *
 * COS 支持舍弃一个分块上传且删除已上传的分片块.
 * 注意，已上传但是未终止的分片块会占用存储空间进
 * 而产生存储费用.因此，建议及时完成分块上传 或者舍弃分块上传.
 *
 * 关于舍弃一个分块上传且删除已上传的分片块接口的描述，请查看 https://cloud.tencent.com/document/product/436/7740
 */
export class AbortMultiUploadRequest extends ObjectRequest {
  uploadId: string;

  constructor(bucket: string, cosPath: string, uploadId: string) {
    super(bucket, cosPath);
    this.uploadId = uploadId;
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
    return undefined;
  }
  public getMethod(): http.RequestMethod {
    return http.RequestMethod.DELETE;
  }
}