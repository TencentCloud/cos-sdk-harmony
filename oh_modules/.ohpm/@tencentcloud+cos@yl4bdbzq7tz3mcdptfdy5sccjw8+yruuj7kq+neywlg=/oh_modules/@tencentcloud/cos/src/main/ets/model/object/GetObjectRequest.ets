import { ObjectRequest } from './ObjectRequest';
import http from '@ohos.net.http';
import { RequestBodySerializer, HttpProgress } from '@tencentcloud/foundation';
import { Range } from '../../common/Range';
import { HttpHeader } from '@tencentcloud/foundation';
import { Callback } from '@ohos.base';
import { TransferRequest } from './TransferRequest';

/**
 * 下载 COS 对象的方法.
 * 下载文件保存本地。
 *
 * 关于获取 COS 对象的接口描述，请查看 https://cloud.tencent.com/document/product/436/7753
 */
export class GetObjectRequest extends ObjectRequest implements TransferRequest {

  /**
   * 下载路径，下载完成后文件会保存至该路径
   */
  filePath: string;
  range?: Range;

  /**
   * 下载文件偏移量。
   * 用于实现断点下载功能。默认情况下，SDK会自动维护断点参数，无需用户进行设置。然而，如果需要自定义断点续传行为，用户可以通过外部指定该参数来实现。
   */
  fileOffset: number = 0;

  constructor(bucket: string, cosPath: string, filePath: string) {
    super(bucket, cosPath);
    this.filePath = filePath;
  }

  onProgress?: Callback<HttpProgress>;

  setRange(start: number, end: number = -1){
    if(start < 0) start = 0;
    let range = new Range(start, end);
    this.removeHeader(HttpHeader.RANGE);
    this.addHeader(HttpHeader.RANGE,range.getRange());
    this.range = range;
  }

  public getBodySerializer(): RequestBodySerializer|undefined {
    return undefined;
  }
  public getMethod(): http.RequestMethod {
    return http.RequestMethod.GET;
  }

  public checkParameters(){
    super.checkParameters();
    // todo 合并校验 定义异常和异常码
    // throw new Error("bucket must not be null ");
    // String normalizedPath = cosPath;
    // try {
    //   File file = new File("/" + cosPath);
    //   normalizedPath = file.getCanonicalPath();
    // } catch (IOException e) {e.printStackTrace();}
    // if ("/".equals(normalizedPath)) {
    //   throw new CosXmlClientException(ClientErrorCode.INVALID_ARGUMENT.getCode(), "The key in the getobject is illegal");
    // }
  }
}