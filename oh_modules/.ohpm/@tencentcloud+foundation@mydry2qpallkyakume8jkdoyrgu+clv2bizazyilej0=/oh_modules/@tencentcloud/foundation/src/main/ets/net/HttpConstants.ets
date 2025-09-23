/**
 * http常量定义
 */
export class HttpHeader {
  public static readonly USER_AGENT = "User-Agent";
  public static readonly CONTENT_TYPE = "Content-Type";
  public static readonly RESPONSE_CONTENT_TYPE = "content-type";
  public static readonly AUTHORIZATION = "Authorization";
  public static readonly CONTENT_LENGTH = "content-length";
  public static readonly CONTENT_MD5 = "Content-MD5";
  public static readonly RANGE = "Range";
  public static readonly CONTENT_RANGE = "content-range";
  public static readonly HOST = "Host";

  public static readonly X_COS_REQUEST_ID = "x-cos-request-id";
  public static readonly X_COS_TRACE_ID = "x-cos-trace-id";
  public static readonly ETAG = "etag";

}

export class ContentType {
  public static readonly XML = "application/xml";
  public static readonly OCTET_STREAM = "application/octet-stream";
  public static readonly JSON = "application/json";
  public static readonly TEXT_PLAIN = "text/plain";
  public static readonly X_WWW_FORM_URLENCODED = "application/x-www-form-urlencoded";
}