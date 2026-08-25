export { HAR_VERSION as COS_VERSION } from './BuildProfile'

export { CosXmlBaseService } from './src/main/ets/CosXmlBaseService'

export { CosXmlServiceConfig } from './src/main/ets/CosXmlServiceConfig'

export type { TransferResultListener } from './src/main/ets/transfer/TransferTask'

export { TransferState } from './src/main/ets/transfer/TransferTask'

export { CosXmlRequest } from './src/main/ets/model/CosXmlRequest'

export { CosXmlResult } from './src/main/ets/model/CosXmlResult'

export { TransferConfig } from './src/main/ets/transfer/TransferConfig'

export { UploadTask, CosXmlUploadTaskResult } from './src/main/ets/transfer/UploadTask'

export { DownloadTask, CosXmlDownloadTaskResult } from './src/main/ets/transfer/DownloadTask'

export { COSStorageClass } from './src/main/ets/common/Constants'

export { Range } from './src/main/ets/common/Range'

export { AbortMultiUploadRequest } from './src/main/ets/model/object/AbortMultiUploadRequest'

export { AbortMultiUploadResult } from './src/main/ets/model/object/AbortMultiUploadResult'

export { CompleteMultiUploadRequest } from './src/main/ets/model/object/CompleteMultiUploadRequest'

export { CompleteMultiUploadResult } from './src/main/ets/model/object/CompleteMultiUploadResult'

export { DeleteObjectRequest } from './src/main/ets/model/object/DeleteObjectRequest'

export { DeleteObjectResult } from './src/main/ets/model/object/DeleteObjectResult'

export { GetObjectArrayBufferRequest } from './src/main/ets/model/object/GetObjectArrayBufferRequest'

export { GetObjectArrayBufferResult } from './src/main/ets/model/object/GetObjectArrayBufferResult'

export { GetObjectRequest } from './src/main/ets/model/object/GetObjectRequest'

export { GetObjectResult } from './src/main/ets/model/object/GetObjectResult'

export { HeadObjectRequest } from './src/main/ets/model/object/HeadObjectRequest'

export { HeadObjectResult } from './src/main/ets/model/object/HeadObjectResult'

export { InitMultipartUploadRequest } from './src/main/ets/model/object/InitMultipartUploadRequest'

export { InitMultipartUploadResult } from './src/main/ets/model/object/InitMultipartUploadResult'

export { DeleteMultipleObjectRequest, DeleteObject } from './src/main/ets/model/object/DeleteMultipleObjectRequest'

export { DeleteMultipleObjectResult,
  DeleteMultipleObject,
  DeletedResult,
  ErrorResult } from './src/main/ets/model/object/DeleteMultipleObjectResult'


export { ListBucketsRequest } from './src/main/ets/model/bucket/ListBucketsRequest'

export { ListBucketsResult, ListBuckets, Bucket } from './src/main/ets/model/bucket/ListBucketsResult'

export { HeadBucketRequest } from './src/main/ets/model/bucket/HeadBucketRequest'

export { HeadBucketResult } from './src/main/ets/model/bucket/HeadBucketResult'

export { ListObjectsRequest } from './src/main/ets/model/object/ListObjectsRequest'

export { ListObjectsResult,
  ListObjects,
  CommonPrefixes,
  Content,
  Owner } from './src/main/ets/model/object/ListObjectsResult'

export { ListPartsRequest } from './src/main/ets/model/object/ListPartsRequest'

export { ListPartsResult } from './src/main/ets/model/object/ListPartsResult'

export { ObjectRequest } from './src/main/ets/model/object/ObjectRequest'

export { PutObjectRequest } from './src/main/ets/model/object/PutObjectRequest'

export { PutObjectResult } from './src/main/ets/model/object/PutObjectResult'

export type { TransferRequest } from './src/main/ets/model/object/TransferRequest'

export { UploadPartRequest } from './src/main/ets/model/object/UploadPartRequest'

export { UploadPartResult } from './src/main/ets/model/object/UploadPartResult'

export { PresignedUrlRequest } from './src/main/ets/model/object/PresignedUrlRequest'

export { ImageInfo } from './src/main/ets/model/pic/ImageInfo'

export { PicObject } from './src/main/ets/model/pic/PicObject'

export { CosError, CosErrorType } from './src/main/ets/error/CosError'

export { CosErrorCode } from './src/main/ets/error/CosErrorCode'

export { CosClientError } from './src/main/ets/error/CosClientError'

export { CosServiceError } from './src/main/ets/error/CosServiceError'

export { CosInvalidArgumentError } from './src/main/ets/error/CosInvalidArgumentError'

export { CosTransferPauseError } from './src/main/ets/error/CosTransferPauseError'

export { PutBucketTagRequest } from './src/main/ets/model/bucket/PutBucketTagRequest'

export { PutBucketTagResult } from './src/main/ets/model/bucket/PutBucketTagResult'

export { GetBucketObjectVersionsRequest } from './src/main/ets/model/bucket/GetBucketObjectVersionsRequest'

export { GetBucketObjectVersionsResult } from './src/main/ets/model/bucket/GetBucketObjectVersionsResult'

export { GetBucketTagRequest } from './src/main/ets/model/bucket/GetBucketTagRequest'

export { GetBucketTagResult } from './src/main/ets/model/bucket/GetBucketTagResult'

export { DeleteBucketTagRequest } from './src/main/ets/model/bucket/DeleteBucketTagRequest'

export { DeleteBucketTagResult } from './src/main/ets/model/bucket/DeleteBucketTagResult'

export { PutBucketRequest } from './src/main/ets/model/bucket/PutBucketRequest'

export { PutBucketResult } from './src/main/ets/model/bucket/PutBucketResult'

export { DeleteBucketRequest } from './src/main/ets/model/bucket/DeleteBucketRequest'

export { DeleteBucketResult } from './src/main/ets/model/bucket/DeleteBucketResult'

export { PutBucketAccelerateRequest } from './src/main/ets/model/bucket/PutBucketAccelerateRequest'

export { PutBucketAccelerateResult } from './src/main/ets/model/bucket/PutBucketAccelerateResult'

export { GetBucketAccelerateRequest } from './src/main/ets/model/bucket/GetBucketAccelerateRequest'

export { GetBucketAccelerateResult, AccelerateConfiguration } from './src/main/ets/model/bucket/GetBucketAccelerateResult'

export { PutBucketVersioningRequest } from './src/main/ets/model/bucket/PutBucketVersioningRequest'

export { PutBucketVersioningResult } from './src/main/ets/model/bucket/PutBucketVersioningResult'

export { GetBucketVersioningRequest } from './src/main/ets/model/bucket/GetBucketVersioningRequest'

export { GetBucketVersioningResult, VersioningConfiguration } from './src/main/ets/model/bucket/GetBucketVersioningResult'

export { GetBucketLocationRequest } from './src/main/ets/model/bucket/GetBucketLocationRequest'

export { GetBucketLocationResult } from './src/main/ets/model/bucket/GetBucketLocationResult'

export { PutObjectTagRequest, TagObject } from './src/main/ets/model/object/PutObjectTagRequest'

export { PutObjectTagResult } from './src/main/ets/model/object/PutObjectTagResult'

export { GetObjectTagRequest } from './src/main/ets/model/object/GetObjectTagRequest'

export { GetObjectTagResult, TaggingResult, TagResult } from './src/main/ets/model/object/GetObjectTagResult'

export { DeleteObjectTagRequest } from './src/main/ets/model/object/DeleteObjectTagRequest'

export { DeleteObjectTagResult } from './src/main/ets/model/object/DeleteObjectTagResult'

export { RestoreObjectRequest } from './src/main/ets/model/object/RestoreObjectRequest'

export { RestoreObjectResult } from './src/main/ets/model/object/RestoreObjectResult'

export { QCloudCredential,
  HttpRequest,
  HttpProgress,
  QCloudAuthenticationError,
  QCloudNetError,
  QCloudTaskError,
  QCloudUserCancelError,
  QCloudLogger } from '@tencentcloud/foundation'

// 自定义网络层
export { NetworkClient,
  NetworkProxy,
  NetworkClientConfig,
  CustomNetworkRequest,
  HarmonyNetworkClient } from '@tencentcloud/foundation'
export type { CustomNetworkResponseHandler } from '@tencentcloud/foundation'
export type { CredentialCallBack } from '@tencentcloud/foundation'

// 凭证缓存：用于主动使本地缓存的临时密钥失效（如切换账号、密钥被回收时）。
// 转发自 foundation，避免调用方为此单独依赖 @tencentcloud/foundation。
export { CredentialCache } from '@tencentcloud/foundation'
