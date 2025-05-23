import http from '@ohos.net.http';
import { CryptoUtil } from '../util/CryptoUtil';
import { HttpHeader } from './HttpConstants';
import { RequestBodySerializer } from './RequestBodySerializer';

import { ResponseBodyConverter } from './ResponseBodyConverter';
import { rpc } from '@kit.IPCKit';
import { rcp } from '@kit.RemoteCommunicationKit';

/**
 * http请求类
 */
export class HttpRequest<T> {
  method: http.RequestMethod;
  protocol: string;
  host: string;
  port: number;
  path: string;
  headers: Map<string, string>;
  queries: Map<string, string | undefined>;
  noSignHeaderKeys: Set<string>;
  noSignQueryKeys: Set<string>;
  isSignedInURL: boolean = false;
  isNeedMD5: boolean = false;
  requestBodySerializer: RequestBodySerializer | undefined;
  responseBodyConverter: ResponseBodyConverter<T>;
  readTimeout: number = 60000; // 单位毫秒（ms）
  connectTimeout: number = 60000; // 单位毫秒（ms）
  dnsOverHttps?: string;
  dnsServers?: string[];
  requestConfiguration?: rcp.Configuration;
  progressGranularity?: number;

  constructor(method: http.RequestMethod, protocol: string, host: string, port: number, path: string,
    requestBodySerializer: RequestBodySerializer | undefined, responseBodyConverter: ResponseBodyConverter<T>,
    headers?: Map<string, string>, queries?: Map<string, string | undefined>, isNeedMD5?: boolean,
    isSignedInURL?: boolean, requestConfiguration?: rcp.Configuration, progressGranularity?: number) {
    this.method = method;
    this.protocol = protocol;
    this.host = host;
    this.port = port;
    this.path = path;
    this.requestBodySerializer = requestBodySerializer;
    this.responseBodyConverter = responseBodyConverter;
    this.headers = headers || new Map();
    this.queries = queries || new Map();
    this.noSignHeaderKeys = new Set();
    this.noSignQueryKeys = new Set();
    this.isNeedMD5 = isNeedMD5 || false;
    this.isSignedInURL = isSignedInURL || false;
    this.requestConfiguration = requestConfiguration;
    this.progressGranularity = progressGranularity;
  }

  addHeader(key: string, value: string): void {
    this.headers.set(key, value);
  }

  shouldRetry(error: Error) {
    return true;
  }

  removeHeader(key: string): void {
    this.headers.delete(key);
  }

  getHeader(key: string): string | undefined {
    return this.headers.get(key);
  }

  addQuery(key: string, value?: string): void {
    this.queries.set(key, value);
  }

  removeQuery(key: string): void {
    this.queries.delete(key);
  }

  getQuery(key: string): string | undefined {
    return this.queries.get(key);
  }

  addNoSignHeaderKey(key: string): void {
    this.noSignHeaderKeys.add(key);
  }

  addNoSignQueryKey(key: string): void {
    this.noSignQueryKeys.add(key);
  }

  setUserAgent(userAgent: string): void {
    this.headers.set(HttpHeader.USER_AGENT, userAgent);
  }

  async prepareRequestData() {
    let buffer = this.requestBodySerializer?.body();
    if (this.isNeedMD5 && buffer) {
      if (buffer instanceof ArrayBuffer) {
        let md5 = await CryptoUtil.qcloudMd5ArrayBuffer(buffer);
        this.addHeader(HttpHeader.CONTENT_MD5, md5);
      }
      if (typeof buffer == 'string') {
        let md5 = await CryptoUtil.qcloudMd5String(buffer);
        this.addHeader(HttpHeader.CONTENT_MD5, md5);
      }
    }


    this.addHeader(HttpHeader.HOST, this.host);

    let contentType = this.requestBodySerializer?.contentType()
    if (!this.headers.get(HttpHeader.CONTENT_TYPE) && contentType) {
      this.addHeader(HttpHeader.CONTENT_TYPE, contentType);
    }

    if (this.requestBodySerializer) {
      let contentLength = this.requestBodySerializer.contentLength()
      this.addHeader(HttpHeader.CONTENT_LENGTH, contentLength.toString());
    }
  }


  /**
   * 生成URL
   * @returns URL
   */
  buildURL(): string {
    let url = `${this.protocol}://${this.host}${this.port == -1 ? "" : `:${this.port}`}/${this.path}`;
    if (this.queries.size > 0) {
      url += '?';
      for (const q of this.queries) {
        if (q[1]) {
          url += `${q[0]}=${encodeURIComponent(q[1])}&`;
        } else {
          url += `${q[0]}&`;
        }
      }
      // Remove the trailing '&'
      url = url.slice(0, -1);
    }
    return url;
  }

  buildBody(): rcp.RequestContent {
    let body = this.requestBodySerializer?.body()
    let headers: Record<string, string> = {};
    this.headers.forEach((value, key) => {
      if (key) {
        headers[key] = value;
      }
    })
    if (body instanceof ArrayBuffer && body.byteLength == 0) {
      body = undefined;
    }
    return body as rcp.RawDataContent;
  }

  buildHeader(): rcp.RequestHeaders {
    let headers: rcp.RequestHeaders = {};
    this.headers.forEach((value, key) => {
      if (key) {
        headers[key] = value;
      }
    })
    return headers;
  }

  buildRequestConfiguration(): rcp.Configuration {
    if (this.requestConfiguration) {
      return this.requestConfiguration;
    }

    const requestConfig: rcp.Configuration = {
      transfer: {
        autoRedirect: false,
        timeout: {
          connectMs: this.connectTimeout,
          transferMs: this.readTimeout
        },
      }
    }

    if (this.dnsServers) {
      if (!requestConfig.dns) {
        requestConfig.dns = {};
      }
      let customDnsServers: rcp.DnsServers = this.dnsServers.map(item => {
        let ipItem: rcp.IpAndPort = { ip: item }
        return ipItem;
      })
      requestConfig.dns.dnsRules = customDnsServers;
    }


    if (this.dnsOverHttps) {
      if (!requestConfig.dns) {
        requestConfig.dns = {};
      }
      let dohConfig: rcp.DnsOverHttpsConfiguration = {
        url: this.dnsOverHttps,
        skipCertificatesValidation: true
      };
      requestConfig.dns.dnsOverHttps = dohConfig;
    }
    return requestConfig;
  }

  reset() {
    this.removeHeader(HttpHeader.AUTHORIZATION);
    this.responseBodyConverter.reset(this);
  }
}
