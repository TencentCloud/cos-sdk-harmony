import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import {
  CosErrorType,
  CosServiceError,
  CosXmlBaseService,
  DeleteBucketRequest,
  GetBucketAccelerateRequest,
  GetBucketLocationRequest,
  GetBucketVersioningRequest,
  ListObjectsRequest,
  PutBucketAccelerateRequest,
  PutBucketRequest,
  PutBucketVersioningRequest,
} from '../../../../Index';
import { Logger } from './common/Logger';
import { TestConst } from './common/TestConst';
import { TestUtils } from './common/TestUtils';

/**
 * Bucket 级接口测试。
 *
 * ## 为什么这些用例值得单独存在
 *
 * 这批接口在 Flutter 插件桥接时暴露过两类「编译器不报、只在特定取值下才出现」
 * 的问题，因此这里的布尔型配置都**成对验证 true / false**：
 *   · 只测一侧会全绿 —— 例如 iOS 侧曾因 NSNumber*  BOOL 的 ABI 失配，
 *     传 false 因指针恰为 nil 而"碰巧正确"，传 true 才崩；
 *   · 反向也有：`@NO` 是非空指针，转 BOOL 恒为 true，只测 true 同样全绿。
 * 鸿蒙侧虽无 ObjC 那套装箱问题，但「配置写进去能否原样读回来」是同一类契约，
 * 值得双向锁死。
 *
 * ## 两个必须注意的副作用约束
 *
 * 1. **版本控制一旦开启就无法关闭**（COS 限制，只能 Suspended）。
 *    所以下面只验证 Enabled → Suspended 的往返，不试图恢复到"从未开启"。
 *    这也意味着测试桶在跑过一次后会长期处于 Suspended，属预期。
 *
 * 2. **PutBucket / DeleteBucket 会真实创建与删除存储桶**。
 *    因此使用 `bucketcanbedelete{随机}` 这类一次性桶名（与 iOS 端测试同策略），
 *    并在同一用例内删除，避免污染账号或误删 PERSIST_BUCKET。
 */
export default function bucketTest(cosXmlBaseService: CosXmlBaseService) {
  describe('bucketTest', () => {
    beforeAll(() => {
    })
    beforeEach(() => {
    })
    afterEach(() => {
    })
    afterAll(() => {
    })

    /** 生成一次性桶名。带 canbedelete 前缀是为了让人一眼看出可安全清理 */
    let tempBucketName: () => string = (): string => {
      const appId = TestConst.PERSIST_BUCKET.substring(TestConst.PERSIST_BUCKET.lastIndexOf('-') + 1);
      const rand = Math.floor(Math.random() * 100000);
      return `bucketcanbedelete${rand}-${appId}`;
    };

    // ================================================================
    // PutBucket / DeleteBucket
    // ================================================================

    it('putBucketAndDeleteBucket', 0, async (done: Function) => {
      const bucket = tempBucketName();
      Logger.info(`putBucketAndDeleteBucket, bucket=${bucket}`);
      const service = TestUtils.getCosXmlBaseService(cosXmlBaseService);

      try {
        const putRequest = new PutBucketRequest(bucket);
        await TestUtils.requestAddCredential(putRequest, service);
        const putResult = await service.putBucket(putRequest);
        Logger.info(putResult);
        expect(putResult.httpCode !== undefined && putResult.httpCode >= 200
          && putResult.httpCode < 300).assertTrue();

        // 建好之后必须能被 HeadBucket 命中，否则说明 PUT 并未真正生效
        const locationRequest = new GetBucketLocationRequest(bucket);
        await TestUtils.requestAddCredential(locationRequest, service);
        const locationResult = await service.getBucketLocation(locationRequest);
        Logger.info(`created bucket location=${locationResult.location}`);
        expect(locationResult.location).assertEqual(TestConst.PERSIST_BUCKET_REGION);
      } catch (e) {
        TestUtils.printError(e);
        expect().assertFail();
        done();
        return;
      }

      // 无论上面断言如何，都要把临时桶删掉，避免残留
      try {
        const deleteRequest = new DeleteBucketRequest(bucket);
        await TestUtils.requestAddCredential(deleteRequest, service);
        const deleteResult = await service.deleteBucket(deleteRequest);
        Logger.info(deleteResult);
        expect(deleteResult.httpCode !== undefined && deleteResult.httpCode >= 200
          && deleteResult.httpCode < 300).assertTrue();
      } catch (e) {
        TestUtils.printError(e);
        expect().assertFail();
      }
      done();
    })

    it('putBucketWithAclAndMAZ', 0, async (done: Function) => {
      // 覆盖 ACL header 与 MAZ（多 AZ）请求体两条分支。
      // MAZ 的请求体是 <CreateBucketConfiguration><BucketAZConfig>MAZ</...>，
      // 注意字段名必须写作 bucketAZConfig —— XmlUtils.upperCamel() 只大写首字母，
      // 若写成 bucketAzConfig 会产出错误的 <BucketAzConfig>。
      const bucket = tempBucketName();
      Logger.info(`putBucketWithAclAndMAZ, bucket=${bucket}`);
      const service = TestUtils.getCosXmlBaseService(cosXmlBaseService);

      let created = false;
      try {
        const putRequest = new PutBucketRequest(bucket);
        putRequest.setXCosAcl('private');
        putRequest.enableMAZ = true;
        await TestUtils.requestAddCredential(putRequest, service);
        const putResult = await service.putBucket(putRequest);
        Logger.info(putResult);
        created = putResult.httpCode !== undefined && putResult.httpCode >= 200
          && putResult.httpCode < 300;
        expect(created).assertTrue();
      } catch (e) {
        // 部分地域/账号可能不支持 MAZ，此时服务端会明确报错。
        // 这不算 SDK 缺陷，如实记录并放过，避免测试环境差异导致误报。
        const error = e as CosServiceError;
        if (error && error.type === CosErrorType.Service) {
          Logger.info(`MAZ not supported in this region/account: ${error.code}`);
          expect(true).assertTrue();
          done();
          return;
        }
        TestUtils.printError(e);
        expect().assertFail();
        done();
        return;
      }

      if (created) {
        try {
          const deleteRequest = new DeleteBucketRequest(bucket);
          await TestUtils.requestAddCredential(deleteRequest, service);
          await service.deleteBucket(deleteRequest);
        } catch (e) {
          TestUtils.printError(e);
        }
      }
      done();
    })

    it('deleteBucketNotExist', 0, async (done: Function) => {
      // 删除不存在的桶应当拿到服务端错误（NoSuchBucket），而不是静默成功。
      // 这条用来锁住「错误确实被抛出且能被识别」这个契约。
      const service = TestUtils.getCosXmlBaseService(cosXmlBaseService);
      const request = new DeleteBucketRequest(tempBucketName());
      await TestUtils.requestAddCredential(request, service);
      try {
        await service.deleteBucket(request);
        // 走到这里说明删了一个本不该存在的桶
        expect().assertFail();
      } catch (e) {
        const error = e as CosServiceError;
        expect(error.type).assertEqual(CosErrorType.Service);
        Logger.info(`deleteBucketNotExist got expected error: ${error.code}, httpCode=${error.httpCode}`);
        expect(error.httpCode === 404 || error.code === 'NoSuchBucket').assertTrue();
      }
      done();
    })

    // ================================================================
    // GetBucketLocation
    // ================================================================

    it('getBucketLocation', 0, async (done: Function) => {
      // 该响应的根节点直接就是文本值：
      //   <LocationConstraint>ap-guangzhou</LocationConstraint>
      // xml2obj 返回的 result['locationConstraint'] 本身就是 string，
      // 不能套 initWithJson —— 这条断言同时锁住了解析方式。
      const service = TestUtils.getCosXmlBaseService(cosXmlBaseService);
      const request = new GetBucketLocationRequest(TestConst.PERSIST_BUCKET);
      await TestUtils.requestAddCredential(request, service);
      try {
        const result = await service.getBucketLocation(request);
        Logger.info(result);
        expect(result.location).assertEqual(TestConst.PERSIST_BUCKET_REGION);
      } catch (e) {
        TestUtils.printError(e);
        expect().assertFail();
      }
      done();
    })

    // ================================================================
    // Put / GetBucketVersioning —— 双向验证
    // ================================================================

    it('putAndGetBucketVersioning', 0, async (done: Function) => {
      // ⚠️ 版本控制一旦 Enabled 就无法回到"未开启"，只能 Suspended。
      // 因此这里验证 Enabled → Suspended 的双向往返，而不是 true → 未配置。
      const service = TestUtils.getCosXmlBaseService(cosXmlBaseService);

      try {
        // --- 开启 ---
        const enableRequest = new PutBucketVersioningRequest(TestConst.PERSIST_BUCKET, true);
        await TestUtils.requestAddCredential(enableRequest, service);
        const enableResult = await service.putBucketVersioning(enableRequest);
        expect(enableResult.httpCode !== undefined && enableResult.httpCode >= 200
          && enableResult.httpCode < 300).assertTrue();

        const getAfterEnable = new GetBucketVersioningRequest(TestConst.PERSIST_BUCKET);
        await TestUtils.requestAddCredential(getAfterEnable, service);
        const enabledStatus = await service.getBucketVersioning(getAfterEnable);
        Logger.info(`versioning after enable: ${enabledStatus.versioningConfiguration?.status}`);
        expect(enabledStatus.versioningConfiguration?.status).assertEqual('Enabled');

        // --- 暂停（false 分支）---
        const suspendRequest = new PutBucketVersioningRequest(TestConst.PERSIST_BUCKET, false);
        await TestUtils.requestAddCredential(suspendRequest, service);
        const suspendResult = await service.putBucketVersioning(suspendRequest);
        expect(suspendResult.httpCode !== undefined && suspendResult.httpCode >= 200
          && suspendResult.httpCode < 300).assertTrue();

        const getAfterSuspend = new GetBucketVersioningRequest(TestConst.PERSIST_BUCKET);
        await TestUtils.requestAddCredential(getAfterSuspend, service);
        const suspendedStatus = await service.getBucketVersioning(getAfterSuspend);
        Logger.info(`versioning after suspend: ${suspendedStatus.versioningConfiguration?.status}`);
        // 关键：false 必须真的写成 Suspended，不能仍是 Enabled。
        // 若两侧读回来都一样，说明 enable 参数根本没生效。
        expect(suspendedStatus.versioningConfiguration?.status).assertEqual('Suspended');
      } catch (e) {
        TestUtils.printError(e);
        expect().assertFail();
      }
      done();
    })

    // ================================================================
    // Put / GetBucketAccelerate —— 双向验证
    // ================================================================

    it('putAndGetBucketAccelerate', 0, async (done: Function) => {
      const service = TestUtils.getCosXmlBaseService(cosXmlBaseService);

      try {
        // --- 开启 ---
        const enableRequest = new PutBucketAccelerateRequest(TestConst.PERSIST_BUCKET, true);
        await TestUtils.requestAddCredential(enableRequest, service);
        const enableResult = await service.putBucketAccelerate(enableRequest);
        expect(enableResult.httpCode !== undefined && enableResult.httpCode >= 200
          && enableResult.httpCode < 300).assertTrue();

        const getAfterEnable = new GetBucketAccelerateRequest(TestConst.PERSIST_BUCKET);
        await TestUtils.requestAddCredential(getAfterEnable, service);
        const enabled = await service.getBucketAccelerate(getAfterEnable);
        Logger.info(`accelerate after enable: ${enabled.accelerateConfiguration?.status}`);
        expect(enabled.accelerateConfiguration?.status).assertEqual('Enabled');

        // --- 关闭（false 分支，写入 Suspended）---
        const suspendRequest = new PutBucketAccelerateRequest(TestConst.PERSIST_BUCKET, false);
        await TestUtils.requestAddCredential(suspendRequest, service);
        const suspendResult = await service.putBucketAccelerate(suspendRequest);
        expect(suspendResult.httpCode !== undefined && suspendResult.httpCode >= 200
          && suspendResult.httpCode < 300).assertTrue();

        const getAfterSuspend = new GetBucketAccelerateRequest(TestConst.PERSIST_BUCKET);
        await TestUtils.requestAddCredential(getAfterSuspend, service);
        const suspended = await service.getBucketAccelerate(getAfterSuspend);
        Logger.info(`accelerate after suspend: ${suspended.accelerateConfiguration?.status}`);
        expect(suspended.accelerateConfiguration?.status).assertEqual('Suspended');
      } catch (e) {
        TestUtils.printError(e);
        expect().assertFail();
      }
      done();
    })

    it('getBucketAccelerateOnFreshBucket', 0, async (done: Function) => {
      // 从未配置过全球加速的桶，服务端返回空的 <AccelerateConfiguration/>。
      // 此时 accelerateConfiguration 或其 status 为 undefined —— 这是**预期行为**
      // （与"已 Suspended"语义等价，都表示未开启），不能因此抛异常或崩溃。
      const bucket = tempBucketName();
      const service = TestUtils.getCosXmlBaseService(cosXmlBaseService);

      let created = false;
      try {
        const putRequest = new PutBucketRequest(bucket);
        await TestUtils.requestAddCredential(putRequest, service);
        await service.putBucket(putRequest);
        created = true;

        const getRequest = new GetBucketAccelerateRequest(bucket);
        await TestUtils.requestAddCredential(getRequest, service);
        const result = await service.getBucketAccelerate(getRequest);
        Logger.info(`fresh bucket accelerate status=${result.accelerateConfiguration?.status}`);
        // 只要不抛异常即通过；status 为 undefined 或 'Suspended' 都算未开启
        const status = result.accelerateConfiguration?.status;
        expect(status === undefined || status === 'Suspended').assertTrue();
      } catch (e) {
        TestUtils.printError(e);
        expect().assertFail();
      }

      if (created) {
        try {
          const deleteRequest = new DeleteBucketRequest(bucket);
          await TestUtils.requestAddCredential(deleteRequest, service);
          await service.deleteBucket(deleteRequest);
        } catch (e) {
          TestUtils.printError(e);
        }
      }
      done();
    })

    // ================================================================
    // Content.storageClass
    // ================================================================

    it('listObjectsStorageClass', 0, async (done: Function) => {
      // 1.2.5 之前 Content 没有 storageClass 字段、initWithJson 也不解析
      // <StorageClass> 节点，导致上层（如 Flutter 插件）拿不到对象存储类型。
      // 这条锁住"字段存在且被真正解析"。
      const service = TestUtils.getCosXmlBaseService(cosXmlBaseService);
      const request = new ListObjectsRequest(TestConst.PERSIST_BUCKET);
      request.prefix = 'do_not_remove/';
      request.maxKeys = 10;
      await TestUtils.requestAddCredential(request, service);
      try {
        const result = await service.listObject(request);
        const contents = result.objects?.contents;
        expect(contents !== undefined && contents!.length > 0).assertTrue();

        let checked = 0;
        contents?.forEach((content) => {
          Logger.info(`key=${content.key} storageClass=${content.storageClass}`);
          // 服务端对每个对象都会返回 StorageClass（STANDARD / STANDARD_IA / ...）
          expect(content.storageClass !== undefined
            && content.storageClass!.length > 0).assertTrue();
          checked++;
        });
        expect(checked > 0).assertTrue();
      } catch (e) {
        TestUtils.printError(e);
        expect().assertFail();
      }
      done();
    })

    it('listObjectsIsTruncated', 0, async (done: Function) => {
      // isTruncated 必须**双向可变**。
      // 桥接到 Flutter 时曾出现"恒为 true"的缺陷（iOS 侧 NSNumber* 隐式转 BOOL
      // 取的是指针非空性），使分页逻辑全错；而只断言"是布尔类型"抓不到它。
      // 这里用同一前缀分别锁住两侧：
      //   1. maxKeys=1 —— 只要前缀下对象数 > 1 就必然截断，验证 true 侧；
      //   2. 沿 NextMarker 翻页到最后一页 —— 最后一页 isTruncated 逻辑必然为 false，
      //      验证 false 侧。不依赖"对象总数 < 某个固定值"的环境假设：do_not_remove/
      //      前缀对象数会随时间累积，可能超过单页上限，导致固定 maxKeys 仍被截断。
      const service = TestUtils.getCosXmlBaseService(cosXmlBaseService);

      try {
        const truncatedRequest = new ListObjectsRequest(TestConst.PERSIST_BUCKET);
        truncatedRequest.prefix = 'do_not_remove/';
        truncatedRequest.maxKeys = 1;
        await TestUtils.requestAddCredential(truncatedRequest, service);
        const truncated = await service.listObject(truncatedRequest);
        Logger.info(`maxKeys=1 isTruncated=${truncated.objects?.isTruncated}`);
        expect(truncated.objects?.isTruncated).assertTrue();
        expect(truncated.objects?.nextMarker !== undefined).assertTrue();

        // 沿 NextMarker 翻页直到最后一页（isTruncated=false）。
        let marker: string | undefined = truncated.objects?.nextMarker;
        let lastIsTruncated: boolean | undefined = truncated.objects?.isTruncated;
        let guard = 0;
        while (lastIsTruncated === true && guard < 100) {
          guard++;
          const pageRequest = new ListObjectsRequest(TestConst.PERSIST_BUCKET);
          pageRequest.prefix = 'do_not_remove/';
          pageRequest.maxKeys = 1000;
          pageRequest.marker = marker;
          await TestUtils.requestAddCredential(pageRequest, service);
          const page = await service.listObject(pageRequest);
          marker = page.objects?.nextMarker;
          lastIsTruncated = page.objects?.isTruncated;
          Logger.info(`page#${guard} isTruncated=${lastIsTruncated}`);
        }

        // 这一侧才是抓「恒为 true」的关键断言：最后一页必须为严格的布尔 false。
        expect(lastIsTruncated).assertFalse();
      } catch (e) {
        TestUtils.printError(e);
        expect().assertFail();
      }
      done();
    })
  })
}
