import { StringUtils } from '@tencentcloud/foundation';

export class ImageInfo{
  format: string|undefined;
  width: number|undefined;
  height: number|undefined;
  quality: number|undefined;
  ave: string|undefined;
  orientation: number|undefined;
  frameCount: number|undefined;

  public static initWithJson(obj:object):ImageInfo{
    let result = new ImageInfo();
    if (obj) {
      result.width = StringUtils.parseInt(obj['width']);
      result.height = StringUtils.parseInt(obj['height']);
      result.quality = StringUtils.parseInt(obj['quality']);
      result.orientation = StringUtils.parseInt(obj['orientation']);
      result.frameCount = StringUtils.parseInt(obj['frameCount']);
      result.format = obj['format'];
      result.ave = obj['ave'];
    }
    return result;
  }
}