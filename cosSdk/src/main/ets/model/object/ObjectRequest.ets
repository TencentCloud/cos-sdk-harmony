import { CosInvalidArgumentError } from '../../error/CosInvalidArgumentError';
import { CosXmlRequest } from '../CosXmlRequest';

export abstract class ObjectRequest extends CosXmlRequest {
  /**
   * cos 文件路径
   */
  cosPath: string;

  constructor(bucket: string, cosPath: string) {
    super();
    this.bucket = bucket;
    this.cosPath = cosPath;
  }

  public getPath(): string {
    return this.cosPath;
  }

  public checkParameters(){
    super.checkParameters();
    if(!this.bucket){
      throw new CosInvalidArgumentError("bucket must not be null ");
    }
    if(!this.cosPath){
      throw new CosInvalidArgumentError("cosPath must not be null ");
    }
    if (this.cosPath.startsWith("/")) {
      throw new CosInvalidArgumentError("cosPath cannot start with /");
    }
  }
}