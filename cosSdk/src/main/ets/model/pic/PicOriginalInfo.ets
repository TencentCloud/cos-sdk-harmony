import { ImageInfo } from './ImageInfo';

export class PicOriginalInfo {
  public key: string | undefined;
  public location: string | undefined;
  public eTag: string | undefined;
  public imageInfo: ImageInfo | undefined;

  public static initWithJson(json:object):PicOriginalInfo{
    let result = new PicOriginalInfo();
    if (json['imageInfo']) {
      result.imageInfo = ImageInfo.initWithJson(json['imageInfo'])
    }
    result.key = json['key'];
    result.location = json['location'];
    result.eTag = json['eTag'];
    return result;
  }
}