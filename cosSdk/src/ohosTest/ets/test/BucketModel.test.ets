import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import {
  CosXmlServiceConfig,
  DeleteBucketRequest,
  DeleteBucketResult,
  GetBucketAccelerateRequest,
  GetBucketAccelerateResult,
  GetBucketLocationRequest,
  GetBucketLocationResult,
  GetBucketVersioningRequest,
  GetBucketVersioningResult,
  ListObjectsResult,
  PutBucketAccelerateRequest,
  PutBucketRequest,
  PutBucketResult,
  PutBucketVersioningRequest,
} from '../../../../Index';
import { StringUtils } from '@tencentcloud/foundation';
import http from '@ohos.net.http';
import { Logger } from './common/Logger';

/**
 * Bucket 级接口的**纯单元测试**（不依赖网络）。
 *
 * 与 Bucket.test.ets（集成测试，走真实 COS 服务）互补：这里直接锁死
 * Request 的序列化（method / query / header / XML body）与 Result 的反序列化
 * （contentParser 对 XML 的解析），从而把几处「只在特定取值下才出错」的坑
 * 在本地、可离线复现地固定下来：
 *
 *   1. PutBucketRequest 的 MAZ 请求体字段名必须是 bucketAZConfig。
 *      XmlUtils.upperCamel() 只大写首字母，若照抄 Android 写成 bucketAzConfig
 *      会产出错误的 <BucketAzConfig>（服务端不识别）。这里用精确字符串断言
 *      锁死「BucketAZConfig 出现、BucketAzConfig 不出现」。
 *
 *   2. GetBucketLocationResult 的响应根节点直接是文本值
 *      （<LocationConstraint>ap-guangzhou</LocationConstraint>），
 *      xml2obj 返回的 result['locationConstraint'] 本身是 string 而非对象，
 *      必须直接取值，不能套 initWithJson。这里直接断言 location 字段。
 *
 *   3. GetBucketAccelerateResult / GetBucketVersioningResult 在服务端返回
 *      空节点（从未配置过）时，configuration 或其 status 为 undefined，
 *      解析必须不抛异常。
 *
 *   4. Content.storageClass能被真正解析。
 */
export default function bucketModelTest() {
  describe('bucketModelTest', () => {
    beforeAll(() => {
    })
    beforeEach(() => {
    })
    afterEach(() => {
    })
    afterAll(() => {
    })

    const config = new CosXmlServiceConfig('ap-guangzhou');

    // ================================================================
    // PutBucketRequest：method / path / header / MAZ body
    // ================================================================

    it('putBucketRequestDefaultNoBody', 0, (done: Function) => {
      const request = new PutBucketRequest('bucket-1253960454');
      expect(request.getMethod()).assertEqual(http.RequestMethod.PUT);
      expect(request.getPath(config)).assertEqual('');
      // 默认非 MAZ：不携带请求体
      expect(request.getBodySerializer() === undefined).assertTrue();
      done();
    })

    it('putBucketRequestMAZBodyUsesBucketAZConfig', 0, (done: Function) => {
      // 核心：字段名必须写作 bucketAZConfig，不能是 bucketAzConfig。
      const request = new PutBucketRequest('bucket-1253960454');
      request.enableMAZ = true;
      const serializer = request.getBodySerializer();
      expect(serializer !== undefined).assertTrue();
      if (serializer) {
        const body = serializer.body();
        expect(typeof body === 'string').assertTrue();
        if (typeof body === 'string') {
          Logger.info(`putBucketMAZ body=${body}`);
          expect(body.indexOf('CreateBucketConfiguration') >= 0).assertTrue();
          expect(body.indexOf('MAZ') >= 0).assertTrue();
          // 大小写锁死：正确的 BucketAZConfig 必须出现，错误的 BucketAzConfig 不得出现
          expect(body.indexOf('BucketAZConfig') >= 0).assertTrue();
          expect(body.indexOf('BucketAzConfig') < 0).assertTrue();
        }
      }
      done();
    })

    it('putBucketRequestHeaders', 0, (done: Function) => {
      // setXCosAcl / setXCosGrantRead / setXCosGrantWrite / setXCosGrantFullControl
      // 都必须落到对应 header 上。
      const request = new PutBucketRequest('bucket-1253960454');
      request.setXCosAcl('private');
      request.setXCosGrantRead('id="100000000001"');
      request.setXCosGrantWrite('id="100000000002"');
      request.setXCosGrantFullControl('id="100000000003"');
      const headers = request.getHeaders();
      expect(headers.get('x-cos-acl')).assertEqual('private');
      expect(headers.get('x-cos-grant-read')).assertEqual('id="100000000001"');
      expect(headers.get('x-cos-grant-write')).assertEqual('id="100000000002"');
      expect(headers.get('x-cos-grant-full-control')).assertEqual('id="100000000003"');
      done();
    })

    // ================================================================
    // PutBucketVersioningRequest / PutBucketAccelerateRequest：body + query
    // ================================================================

    it('putBucketVersioningRequestBodyAndQuery', 0, (done: Function) => {
      const enabled = new PutBucketVersioningRequest('bucket-1253960454', true);
      expect(enabled.getMethod()).assertEqual(http.RequestMethod.PUT);
      expect(enabled.getQueries().has('versioning')).assertTrue();
      const enabledBody = enabled.getBodySerializer();
      expect(enabledBody !== undefined).assertTrue();
      if (enabledBody) {
        const body = enabledBody.body();
        expect(typeof body === 'string').assertTrue();
        if (typeof body === 'string') {
          expect(body.indexOf('VersioningConfiguration') >= 0).assertTrue();
          expect(body.indexOf('Enabled') >= 0).assertTrue();
        }
      }

      const suspended = new PutBucketVersioningRequest('bucket-1253960454', false);
      const suspendedBody = suspended.getBodySerializer();
      expect(suspendedBody !== undefined).assertTrue();
      if (suspendedBody) {
        const body = suspendedBody.body();
        if (typeof body === 'string') {
          expect(body.indexOf('Suspended') >= 0).assertTrue();
          // false 分支绝不能仍输出 Enabled
          expect(body.indexOf('Enabled') < 0).assertTrue();
        }
      }
      done();
    })

    it('putBucketAccelerateRequestBodyAndQuery', 0, (done: Function) => {
      const enabled = new PutBucketAccelerateRequest('bucket-1253960454', true);
      expect(enabled.getMethod()).assertEqual(http.RequestMethod.PUT);
      expect(enabled.getQueries().has('accelerate')).assertTrue();
      const enabledBody = enabled.getBodySerializer();
      expect(enabledBody !== undefined).assertTrue();
      if (enabledBody) {
        const body = enabledBody.body();
        if (typeof body === 'string') {
          expect(body.indexOf('AccelerateConfiguration') >= 0).assertTrue();
          expect(body.indexOf('Enabled') >= 0).assertTrue();
        }
      }

      const suspended = new PutBucketAccelerateRequest('bucket-1253960454', false);
      const suspendedBody = suspended.getBodySerializer();
      if (suspendedBody) {
        const body = suspendedBody.body();
        if (typeof body === 'string') {
          expect(body.indexOf('Suspended') >= 0).assertTrue();
          expect(body.indexOf('Enabled') < 0).assertTrue();
        }
      }
      done();
    })

    // ================================================================
    // GET / DELETE 请求：method + query
    // ================================================================

    it('bucketGetAndDeleteRequests', 0, (done: Function) => {
      const location = new GetBucketLocationRequest('bucket-1253960454');
      expect(location.getMethod()).assertEqual(http.RequestMethod.GET);
      expect(location.getQueries().has('location')).assertTrue();
      expect(location.getBodySerializer() === undefined).assertTrue();

      const versioning = new GetBucketVersioningRequest('bucket-1253960454');
      expect(versioning.getMethod()).assertEqual(http.RequestMethod.GET);
      expect(versioning.getQueries().has('versioning')).assertTrue();

      const accelerate = new GetBucketAccelerateRequest('bucket-1253960454');
      expect(accelerate.getMethod()).assertEqual(http.RequestMethod.GET);
      expect(accelerate.getQueries().has('accelerate')).assertTrue();

      const del = new DeleteBucketRequest('bucket-1253960454');
      expect(del.getMethod()).assertEqual(http.RequestMethod.DELETE);
      expect(del.getBodySerializer() === undefined).assertTrue();
      done();
    })

    // ================================================================
    // Result 反序列化
    // ================================================================

    it('getBucketLocationResultParsesTextRoot', 0, (done: Function) => {
      // 根节点直接是文本值，location 必须是字符串而非对象。
      const xml = '<LocationConstraint>ap-guangzhou</LocationConstraint>';
      const result = new GetBucketLocationResult();
      result.parseResponseBody(200, {}, StringUtils.stringToBuffer(xml));
      expect(result.httpCode).assertEqual(200);
      expect(result.location).assertEqual('ap-guangzhou');
      done();
    })

    it('getBucketAccelerateResultParsesConfiguration', 0, (done: Function) => {
      const xml = '<AccelerateConfiguration><Status>Enabled</Status><Type>COS</Type></AccelerateConfiguration>';
      const result = new GetBucketAccelerateResult();
      result.parseResponseBody(200, {}, StringUtils.stringToBuffer(xml));
      expect(result.accelerateConfiguration?.status).assertEqual('Enabled');
      expect(result.accelerateConfiguration?.type).assertEqual('COS');
      done();
    })

    it('getBucketAccelerateResultEmptyNodeNoThrow', 0, (done: Function) => {
      // 服务端对从未配置过全球加速的桶返回空节点，解析不得抛异常，
      // configuration 或 status 为 undefined 都表示未开启。
      const xml = '<AccelerateConfiguration/>';
      const result = new GetBucketAccelerateResult();
      result.parseResponseBody(200, {}, StringUtils.stringToBuffer(xml));
      expect(result.accelerateConfiguration === undefined
        || result.accelerateConfiguration.status === undefined).assertTrue();
      done();
    })

    it('getBucketVersioningResultParsesConfiguration', 0, (done: Function) => {
      const xml = '<VersioningConfiguration><Status>Suspended</Status></VersioningConfiguration>';
      const result = new GetBucketVersioningResult();
      result.parseResponseBody(200, {}, StringUtils.stringToBuffer(xml));
      expect(result.versioningConfiguration?.status).assertEqual('Suspended');
      done();
    })

    it('putAndDeleteResultRequestIdFromHeader', 0, (done: Function) => {
      // PutBucketResult / DeleteBucketResult 等无响应体结果，requestId() 从
      // 响应头 x-cos-request-id 提取。这条锁住"header 能被正确读到"。
      const putResult = new PutBucketResult();
      putResult.parseResponseBody(200, { 'x-cos-request-id': 'req-id-put' }, new ArrayBuffer(0));
      expect(putResult.httpCode).assertEqual(200);
      expect(putResult.requestId()).assertEqual('req-id-put');

      const deleteResult = new DeleteBucketResult();
      deleteResult.parseResponseBody(204, { 'x-cos-request-id': 'req-id-del' }, new ArrayBuffer(0));
      expect(deleteResult.httpCode).assertEqual(204);
      expect(deleteResult.requestId()).assertEqual('req-id-del');
      done();
    })

    it('contentStorageClassParsed', 0, (done: Function) => {
      // Content.storageClass 是 1.2.5 新增字段，这里锁死 <StorageClass> 被真正解析。
      const xml = '<ListBucketResult>' +
        '<Contents><Key>a.txt</Key><StorageClass>STANDARD_IA</StorageClass></Contents>' +
        '<Contents><Key>b.txt</Key><StorageClass>STANDARD</StorageClass></Contents>' +
        '</ListBucketResult>';
      const result = new ListObjectsResult();
      result.parseResponseBody(200, {}, StringUtils.stringToBuffer(xml));
      const contents = result.objects?.contents;
      expect(contents !== undefined).assertTrue();
      if (contents) {
        let first: string | undefined = undefined;
        let second: string | undefined = undefined;
        contents.forEach((content, idx) => {
          if (idx === 0) {
            first = content.storageClass;
          }
          if (idx === 1) {
            second = content.storageClass;
          }
        });
        expect(first).assertEqual('STANDARD_IA');
        expect(second).assertEqual('STANDARD');
      }
      done();
    })
  })
}
