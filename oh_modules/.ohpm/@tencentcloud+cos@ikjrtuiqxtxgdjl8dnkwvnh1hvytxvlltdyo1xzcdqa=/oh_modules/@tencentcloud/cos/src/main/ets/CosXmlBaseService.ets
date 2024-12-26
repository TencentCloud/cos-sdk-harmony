import {
  QCloudHttpRequest,
  QCloudHTTPTask,
  QCloudTaskManager,
  HttpProgress,
  HttpResponse,
  ResponseBodyConverter,
  CredentialCallBack,
  QCloudLogger,
  RetryHandler,
  QCloudSignatureBuilder,
  SelfSignCallBack
} from '@tencentcloud/foundation';
import { CosXmlRequest } from './model/CosXmlRequest';
import { CosXmlResult } from './model/CosXmlResult';
import { GetObjectRequest } from './model/object/GetObjectRequest';
import { GetObjectResult } from './model/object/GetObjectResult';
import { CosXmlServiceConfig } from './CosXmlServiceConfig';
import { ResponseCosXmlConverter } from './converter/ResponseCosXmlConverter';
import { ResponseArrayBufferConverter } from './converter/ResponseArrayBufferConverter';
import { GetObjectArrayBufferRequest } from './model/object/GetObjectArrayBufferRequest';
import { GetObjectArrayBufferResult } from './model/object/GetObjectArrayBufferResult';
import { DeleteObjectRequest } from './model/object/DeleteObjectRequest';
import { DeleteObjectResult } from './model/object/DeleteObjectResult';
import { HeadObjectRequest } from './model/object/HeadObjectRequest';
import { HeadObjectResult } from './model/object/HeadObjectResult';
import { InitMultipartUploadRequest } from './model/object/InitMultipartUploadRequest';
import { InitMultipartUploadResult } from './model/object/InitMultipartUploadResult';
import { ListPartsRequest } from './model/object/ListPartsRequest';
import { ListPartsResult } from './model/object/ListPartsResult';
import { AbortMultiUploadRequest } from './model/object/AbortMultiUploadRequest';
import { AbortMultiUploadResult } from './model/object/AbortMultiUploadResult';
import { CompleteMultiUploadRequest } from './model/object/CompleteMultiUploadRequest';
import { CompleteMultiUploadResult } from './model/object/CompleteMultiUploadResult';
import { UploadTask } from './transfer/UploadTask';
import { TransferConfig } from './transfer/TransferConfig';
import { DownloadTask } from './transfer/DownloadTask';
import { TransferRequest } from './model/object/TransferRequest';
import { Callback } from '@ohos.base';
import { PutObjectRequest } from './model/object/PutObjectRequest';
import { UploadPartRequest } from './model/object/UploadPartRequest';
import { UploadPartResult } from './model/object/UploadPartResult';
import { ResponseFileConverter } from './converter/ResponseFileConverter';
import { PutObjectResult } from './model/object/PutObjectResult';
import { CosErrorUtils } from './util/CosErrorUtils';
import { PresignedUrlRequest } from './model/object/PresignedUrlRequest';
import { PresignedUrlResult } from './model/object/PresignedUrlResult';
import { ListBucketsRequest } from './model/bucket/ListBucketsRequest';
import { ListBucketsResult } from './model/bucket/ListBucketsResult';
import { HeadBucketResult } from './model/bucket/HeadBucketResult';
import { HeadBucketRequest } from './model/bucket/HeadBucketRequest';
import { ListObjectsRequest } from './model/object/ListObjectsRequest';
import { ListObjectsResult } from './model/object/ListObjectsResult';
import { DeleteMultipleObjectRequest } from './model/object/DeleteMultipleObjectRequest';
import { DeleteMultipleObjectResult } from './model/object/DeleteMultipleObjectResult';
import { GetBucketObjectVersionsRequest } from './model/bucket/GetBucketObjectVersionsRequest';
import { GetBucketObjectVersionsResult } from './model/bucket/GetBucketObjectVersionsResult';
import { GetBucketTagRequest } from './model/bucket/GetBucketTagRequest';
import { PutBucketTagRequest } from './model/bucket/PutBucketTagRequest';
import { DeleteBucketTagRequest } from './model/bucket/DeleteBucketTagRequest';
import { DeleteBucketTagResult } from './model/bucket/DeleteBucketTagResult';
import { PutObjectTagRequest } from './model/object/PutObjectTagRequest';
import { PutObjectTagResult } from './model/object/PutObjectTagResult';
import { GetBucketTagResult } from './model/bucket/GetBucketTagResult';
import { DeleteObjectTagResult } from './model/object/DeleteObjectTagResult';
import { DeleteObjectTagRequest } from './model/object/DeleteObjectTagRequest';
import { GetObjectTagRequest, GetObjectTagResult, PutBucketTagResult } from '../../../Index';

/**
 * 提供用于访问Tencent Cloud COS服务的基础服务类。
 * 在调用 COS 服务前，都必须初始化一个该类的对象。
 *
 * 使用步骤：
 *    第一步：创建服务配置。更多参数请参考 CosXmlServiceConfig 类；
 *      let config = new CosXmlServiceConfig("ap-guangzhou");
 *
 *    第二步：创建访问凭证回调。（可选设置，也可使用CosXmlRequest->credential 设置访问凭证。CosXmlRequest->credential 优先级高于 CosXmlBaseService->credentialCallBack）
 *      这里可以使用永久密钥，也可用临时密钥。
 *         临时密钥请查看：https://cloud.tencent.com/document/product/436/14048
 *         永久密钥请查看：https://console.cloud.tencent.com/cam/capi
 *
 *      public static credentialCallBack: CredentialCallBack = (request)=>{
 *         return new Promise((resolve, reject) => {
 *           let credential : QCloudCredential= new QCloudCredential();
 *           credential.secretID = "secretID";
 *           credential.secretKey = "secretKey";
 *           credential.expirationDate = "expirationDate";
 *           credential.startDate = "startDate";
 *           credential.token = "token"; // 永久密钥无token
 *           resolve(credential)
 *       })
 *     }
 *
 *    第三步：初始化 cos 服务实例
 *     1. 初始化默认示例，建议初始化一次。
 *         let config = new CosXmlServiceConfig("ap-guangzhou");
 *         CosXmlBaseService.initDefaultService(this.context.getApplicationContext(),config,credentialCallBack)
 *
 *     2. 初始化自定义服务实例，可创建多个
 *         let config = new CosXmlServiceConfig("ap-guangzhou");
 *         let service = new CosXmlBaseService(this.context.getApplicationContext(),config,credentialCallBack)
 *
 * 完整示例代码：
 *
 *    let config = new CosXmlServiceConfig("ap-guangzhou");
 *
 *    public static credentialCallBack: CredentialCallBack = (request)=>{
 *       return new Promise((resolve, reject) => {
 *         let credential : QCloudCredential= new QCloudCredential();
 *         credential.secretID = "secretID";
 *         credential.secretKey = "secretKey";
 *         credential.expirationDate = "expirationDate";
 *         credential.startDate = "startDate";
 *         credential.token = "token"; // 永久密钥无token
 *         resolve(credential)
 *       })
 *     }
 *
 *     CosXmlBaseService.initDefaultService(this.context.getApplicationContext(),config,credentialCallBack)
 *
 *     // 根据业务，选择性创建自定义 服务实例
 *     let service = new CosXmlBaseService(this.context.getApplicationContext(),config,credentialCallBack)
 *
 */
export class CosXmlBaseService {
  private readonly context: Context;
  /**
   * 是否调试模式
   * 非调试模式，关闭日志。
   */
  private static isDebuggable: boolean = false;

  public static setDebuggable(isDebuggable: boolean) {
    CosXmlBaseService.isDebuggable = isDebuggable;
    QCloudLogger.setClose(!CosXmlBaseService.isDebuggable);
  }

  /**
   * cos 服务配置
   */
  public readonly cosXmlServiceConfig: CosXmlServiceConfig;
  /**
   * 获取密钥凭证回调，根据实际场景，sdk提供是两种密钥设置方式。
   *
   * 场景一：每个请求有特定的访问凭证，且不通用。
   *    可以不设置 credentialCallBack。使用 CosXmlRequest->credential参数 设置当前请求的访问凭证。
   *
   * 场景二：所有请求通用访问凭证。
   *    请设置当前参数 credentialCallBack；
   */
  public readonly credentialCallBack?: CredentialCallBack;
  private selfSignCallBack?: SelfSignCallBack;

  /**
   * 设置自签名回调
   */
  public setSelfSignCallBack(selfSignCallBack: SelfSignCallBack) {
    this.selfSignCallBack = selfSignCallBack;
  }

  constructor(context: Context, cosXmlServiceConfig: CosXmlServiceConfig, credentialCallBack?: CredentialCallBack) {
    this.context = context;
    this.cosXmlServiceConfig = cosXmlServiceConfig;
    this.credentialCallBack = credentialCallBack;
    QCloudTaskManager.manager().setDownloadConcurrentCount(cosXmlServiceConfig.downloadMaxConcurrentCount);
    QCloudTaskManager.manager().setUploadConcurrentCount(cosXmlServiceConfig.uploadMaxConcurrentCount);
  }

  private static defaultService: CosXmlBaseService;

  /**
   * 获取默认的COS对外服务
   * @returns
   */
  public static default(): CosXmlBaseService {
    return CosXmlBaseService.defaultService;
  }

  /**
   * 初始化默认的COS对外服务
   * @param context context
   * @param cosXmlServiceConfig cos服务配置
   */
  public static initDefaultService(context: Context, cosXmlServiceConfig: CosXmlServiceConfig,
    credentialCallBack?: CredentialCallBack) {
    CosXmlBaseService.defaultService = new CosXmlBaseService(context, cosXmlServiceConfig, credentialCallBack);
  }

  /**
   * 构建网络请求
   */
  protected buildHttpRequest<T1 extends CosXmlRequest, T2 extends CosXmlResult>(cosXmlRequest: T1,
    cosXmlResult: T2): QCloudHttpRequest<T2> {
    cosXmlRequest.checkParameters();
    // 设置ResponseBodyConverter
    let responseBodyConverter: ResponseBodyConverter<T2>;
    if (cosXmlRequest instanceof GetObjectRequest) {
      responseBodyConverter =
        new ResponseFileConverter<T2>(cosXmlRequest.filePath, cosXmlRequest.fileOffset, cosXmlResult,
          this.cosXmlServiceConfig.progressGranularity, cosXmlRequest.onProgress);
    } else if (cosXmlRequest instanceof GetObjectArrayBufferRequest) {
      responseBodyConverter = new ResponseArrayBufferConverter<T2>(cosXmlResult);
    } else {
      responseBodyConverter = new ResponseCosXmlConverter<T2>(cosXmlResult);
    }
    let qcloudHttpRequest = new QCloudHttpRequest<T2>(
      cosXmlRequest.getMethod(),
      this.cosXmlServiceConfig.protocol,
      this.cosXmlServiceConfig.getRequestHost(cosXmlRequest.bucket, cosXmlRequest.region),
      this.cosXmlServiceConfig.port,
      cosXmlRequest.getPath(this.cosXmlServiceConfig),
      cosXmlRequest.getBodySerializer(),
      responseBodyConverter!,
      new Map([...Array.from(cosXmlRequest.getHeaders().entries()),
        ...Array.from(this.cosXmlServiceConfig.headers.entries())]),
      cosXmlRequest.getQueries(),
      cosXmlRequest.isNeedMD5,
      cosXmlRequest.isSignedInURL,
      this.cosXmlServiceConfig.requestConfiguration,
      this.cosXmlServiceConfig.progressGranularity
    );
    qcloudHttpRequest.noSignHeaderKeys =
      new Set(Array.from(cosXmlRequest.noSignHeaderKeys).concat(Array.from(this.cosXmlServiceConfig.noSignHeaderKeys)));
    qcloudHttpRequest.noSignQueryKeys = cosXmlRequest.noSignQueryKeys;
    qcloudHttpRequest.readTimeout = this.cosXmlServiceConfig.readTimeout;
    qcloudHttpRequest.connectTimeout = this.cosXmlServiceConfig.connectTimeout;
    qcloudHttpRequest.dnsOverHttps = this.cosXmlServiceConfig.dnsOverHttps;
    qcloudHttpRequest.dnsServers = this.cosXmlServiceConfig.dnsServers;
    qcloudHttpRequest.credential = cosXmlRequest.credential;
    qcloudHttpRequest.credentialCallBack = this.credentialCallBack;
    if (this.selfSignCallBack) {
      qcloudHttpRequest.selfSignCallBack = this.selfSignCallBack;
    }
    return qcloudHttpRequest;
  }

  protected async execute<T1 extends CosXmlRequest, T2 extends CosXmlResult>(cosXmlRequest: T1,
    cosXmlResult: T2): Promise<T2> {
    return new Promise((resolve, reject) => {
      try {
        let qcloudHttpRequest = this.buildHttpRequest(cosXmlRequest, cosXmlResult);

        // let task: QCloudHTTPTask<T2> = this.qcloudHttpClient.resolveRequest(qcloudHttpRequest, );
        let task: QCloudHTTPTask<T2> = new QCloudHTTPTask(qcloudHttpRequest);
        task.priority = cosXmlRequest.priority;
        task.retry = new RetryHandler(this.cosXmlServiceConfig.maxRetryCount, this.cosXmlServiceConfig.retrySleep);
        cosXmlRequest.taskId = task.taskId;
        // task设置回调
        task.onHeaderReceive = (header: Record<string, string>) => {
          let callbackHeaderReceive = cosXmlRequest.onHeaderReceive;
          if (callbackHeaderReceive) {
            callbackHeaderReceive(header);
          }
        };
        task.onProgress = (progress: HttpProgress) => {
          // GetObjectRequest的进度在ResponseFileConverter中回调，因为存在重试range影响进度总量的问题
          if (cosXmlRequest instanceof GetObjectRequest) {
            return;
          }
          let callbackProgress: Callback<HttpProgress> | undefined =
            ((cosXmlRequest as object) as TransferRequest).onProgress;
          if (callbackProgress) {
            callbackProgress(progress);
          }
        };
        task.onSuccess = (response: HttpResponse<T2>) => {
          if (cosXmlRequest.onSuccess) {
            cosXmlRequest.onSuccess(cosXmlResult);
          }
          QCloudLogger.debug(`execute_onSuccess:${cosXmlRequest}`, 'CosXmlBaseService');
          resolve(cosXmlResult);
        };
        task.onFailure = (err: Error) => {
          let cosError = CosErrorUtils.transformCosError(err);
          if (cosXmlRequest.onFailure) {
            cosXmlRequest.onFailure(cosError);
          }
          QCloudLogger.debug(`execute_onFailure:${cosError}`, 'CosXmlBaseService');
          reject(cosError);
        };
        // 根据request类型addTask
        if (cosXmlRequest instanceof GetObjectRequest || cosXmlRequest instanceof GetObjectArrayBufferRequest) {
          QCloudTaskManager.manager().addDownloadTask(task);
        } else if (
          cosXmlRequest instanceof AbortMultiUploadRequest ||
            cosXmlRequest instanceof CompleteMultiUploadRequest ||
            cosXmlRequest instanceof InitMultipartUploadRequest ||
            cosXmlRequest instanceof ListPartsRequest ||
            cosXmlRequest instanceof PutObjectRequest ||
            cosXmlRequest instanceof UploadPartRequest
        ) {
          QCloudTaskManager.manager().addUploadTask(task);
        } else {
          QCloudTaskManager.manager().addRequestTask(task);
        }
      } catch (error) {
        let cosError = CosErrorUtils.transformCosError(error);
        if (cosXmlRequest.onFailure) {
          cosXmlRequest.onFailure(cosError);
        }
        QCloudLogger.debug(`execute_onFailure:${cosError}`, 'CosXmlBaseService');
        reject(cosError);
      }
    });
  }

  public async getObject(request: GetObjectRequest): Promise<GetObjectResult> {
    let result = await this.execute(request, new GetObjectResult());
    result.accessUrl = this.getAccessUrl(request);
    return result;
  }

  public async getObjectToArrayBuffer(request: GetObjectArrayBufferRequest): Promise<ArrayBuffer | undefined> {
    let getObjectArrayBufferResult = new GetObjectArrayBufferResult();
    let result = await this.execute(request, getObjectArrayBufferResult);
    return result.arrayBuffer;
  }

  public async deleteObject(request: DeleteObjectRequest): Promise<DeleteObjectResult> {
    let result = await this.execute(request, new DeleteObjectResult());
    return result;
  }

  public async getBucketTag(request: GetBucketTagRequest): Promise<GetBucketTagResult> {
    let result = await this.execute(request, new GetBucketTagResult());
    return result;
  }

  public async putBucketTag(request: PutBucketTagRequest): Promise<PutBucketTagResult> {
    let result = await this.execute(request, new PutBucketTagResult());
    return result;
  }

  public async deleteBucketTag(request: DeleteBucketTagRequest): Promise<DeleteBucketTagResult> {
    let result = await this.execute(request, new DeleteBucketTagResult());
    return result;
  }

  public async putObjectTag(request: PutObjectTagRequest): Promise<PutObjectTagResult> {
    let result = await this.execute(request, new PutObjectTagResult());
    return result;
  }

  public async getObjectTag(request: GetObjectTagRequest): Promise<GetObjectTagResult> {
    let result = await this.execute(request, new GetObjectTagResult());
    return result;
  }

  public async deleteObjectTag(request: DeleteObjectTagRequest): Promise<DeleteObjectTagResult> {
    let result = await this.execute(request, new DeleteObjectTagResult());
    return result;
  }

  public async headObject(request: HeadObjectRequest): Promise<HeadObjectResult> {
    let result = await this.execute(request, new HeadObjectResult());
    result.accessUrl = this.getAccessUrl(request);
    return result;
  }

  public async headBucket(request: HeadBucketRequest): Promise<HeadBucketResult> {
    let result = await this.execute(request, new HeadBucketResult());
    return result;
  }

  public async initMultipartUpload(request: InitMultipartUploadRequest): Promise<InitMultipartUploadResult> {
    let result = await this.execute(request, new InitMultipartUploadResult());
    return result;
  }

  public async listParts(request: ListPartsRequest): Promise<ListPartsResult> {
    let result = await this.execute(request, new ListPartsResult());
    return result;
  }

  public async abortMultiUpload(request: AbortMultiUploadRequest): Promise<AbortMultiUploadResult> {
    let result = await this.execute(request, new AbortMultiUploadResult());
    return result;
  }

  public async partUpload(request: UploadPartRequest): Promise<UploadPartResult> {
    let result = await this.execute(request, new UploadPartResult());
    return result;
  }

  public async completeMultiUpload(request: CompleteMultiUploadRequest): Promise<CompleteMultiUploadResult> {
    let result = await this.execute(request, new CompleteMultiUploadResult());
    result.accessUrl = this.getAccessUrl(request);
    return result;
  }

  public async putObject(request: PutObjectRequest): Promise<PutObjectResult> {
    let result = await this.execute(request, new PutObjectResult());
    result.accessUrl = this.getAccessUrl(request);
    return result;
  }

  public async listBucket(request: ListBucketsRequest): Promise<ListBucketsResult> {
    let result = await this.execute(request, new ListBucketsResult());
    return result;
  }

  public async listObject(request: ListObjectsRequest): Promise<ListObjectsResult> {
    let result = await this.execute(request, new ListObjectsResult());
    return result;
  }

  public async deleteMultipleObject(request: DeleteMultipleObjectRequest): Promise<DeleteMultipleObjectResult> {
    let result = await this.execute(request, new DeleteMultipleObjectResult());
    return result;
  }

  public async getBucketObjectVersions(request: GetBucketObjectVersionsRequest): Promise<GetBucketObjectVersionsResult> {
    let result = await this.execute(request, new GetBucketObjectVersionsResult());
    return result;
  }

  public upload(putObjectRequest: PutObjectRequest, uploadId?: string, config?: TransferConfig): UploadTask {
    return new UploadTask(this, putObjectRequest, uploadId, config);
  }

  public download(getObjectRequest: GetObjectRequest): DownloadTask {
    return new DownloadTask(this.context, this, getObjectRequest);
  }

  /**
   * 生成预签名链接
   */
  public async buildPresignedUrl(presignedUrlRequest: PresignedUrlRequest): Promise<string> {
    let httpRequest = this.buildHttpRequest(presignedUrlRequest, new PresignedUrlResult());
    await httpRequest.prepareRequestData();
    let url = httpRequest?.buildURL();
    let signature = await QCloudSignatureBuilder.signatureBuild(httpRequest);
    if (signature) {
      if (url.includes("?")) {
        url += `&${signature.authorization}`;
      } else {
        url += `?${signature.authorization}`;
      }
      if (signature.token && signature.token.length > 0) {
        url += `&${signature.tokenName}=${signature.token}`;
      }
    }
    return url;
  }

  public cancel(request: CosXmlRequest) {
    if (request.taskId) {
      QCloudTaskManager.manager().cancel(request.taskId);
    }
  }

  public cancelAll() {
    QCloudTaskManager.manager().cancelAll();
  }

  public getAccessUrl(request: CosXmlRequest): string {
    let url =
      `${this.cosXmlServiceConfig.protocol}://${this.cosXmlServiceConfig.getRequestHost(request.bucket,
        request.region)}/${request.getPath(this.cosXmlServiceConfig)}`;
    return url;
  }
}