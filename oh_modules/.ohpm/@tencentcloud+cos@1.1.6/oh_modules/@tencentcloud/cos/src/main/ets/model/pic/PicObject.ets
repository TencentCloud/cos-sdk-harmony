import { StringUtils } from '@tencentcloud/foundation';

export class PicObject{
  key?: string;
  location?: string;
  format?: string;
  width?: number;
  height?: number;
  size?: number;
  quality?: number;
  etag?: string;
  frameCount?: number;

  constructor(key?: string, location?: string, format?: string, width?: number, height?: number, size?: number,
    quality?: number, etag?: string, frameCount?: number) {
    this.key = key;
    this.location = location;
    this.format = format;
    this.width = width;
    this.height = height;
    this.size = size;
    this.quality = quality;
    this.etag = etag;
    this.frameCount = frameCount;
  }

  public static initWithJson(json:object):PicObject{
    if (!json) {
      return new PicObject();
    }
    let result = new PicObject(json['key'],json['location'],json['format'],StringUtils.parseInt(json['width']),StringUtils.parseInt(json['height']),StringUtils.parseInt(json['size']),StringUtils.parseInt(json['quality']),json['etag'],StringUtils.parseInt(json['frameCount']));
    return result;
  }
}