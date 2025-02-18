## 准备工作
1. 您需要一个鸿蒙 NEXT 应用，这个应用可以是您现有的工程，也可以是您新建的一个空的工程。

2. 请确保您的鸿蒙 NEXT 应用目标为 API 级别 12 或更高版本。


## 第一步：集成 SDK
1. 运行此命令进行 SDK 依赖安装：

   ``` bash
      ohpm install @tencentcloud/cos
   ```

   这将向您工程的 oh-package.json5 添加这样一行依赖代码：

   ``` bash
      "dependencies": {
         ...
         "@tencentcloud/cos":"1.1.5"
      }
   ```
2. SDK 需要网络权限，用于与 COS 服务器进行通信，请在应用模块下的 module.json5 中添加如下权限声明：

   ``` bash
   ...
   "requestPermissions":[
     {
       "name" : "ohos.permission.INTERNET",
       ...
     }
   ]
   ...
   ```

## 第三步：开始使用

> **注意**
> 
> - 建议用户 [使用临时密钥](https://cloud.tencent.com/document/product/436/14048) 调用 SDK，通过临时授权的方式进一步提高 SDK 使用的安全性。申请临时密钥时，请遵循 [最小权限指引原则](https://cloud.tencent.com/document/product/436/38618)，防止泄露目标存储桶或对象之外的资源。
> - 如果您一定要使用永久密钥，建议遵循 [最小权限指引原则](https://cloud.tencent.com/document/product/436/38618) 对永久密钥的权限范围进行限制。
> - 为了您的业务安全，上传文件可参见 [上传安全限制](https://write.woa.com/document/137498679378300928)。


### 1. 初始化密钥


【单次临时秘钥】

将单个密钥设置给具体的 CosXmlRequest（例如上传的 PutObjectRequest等），该密钥仅用于本次 COS 操作（例如上传等）。
``` typescript
import { QCloudCredential } from '@tencentcloud/cos';

// 获取临时密钥（业务层控制获取的方式）
let credential : QCloudCredential= new QCloudCredential();
credential.secretID = "secretID";
credential.secretKey = "secretKey";
credential.token = "token";
credential.startDate = new Date();
credential.expirationDate = new Date();
```


【临时密钥回调】

采用回调的方式给 COS SDK 提供获取临时密钥的方法，SDK 会在首次和缓存的临时密钥快过期时使用该回调重新获取临时密钥。
``` typescript
import { CredentialCallBack, QCloudCredential } from '@tencentcloud/cos';

export class Credential {
  /**
   * 获取STS临时秘钥
   */
  public static sessionCredential: CredentialCallBack = (request)=>{
    return new Promise((resolve, reject) => {
      // 首先从您的临时密钥服务器获取包含了密钥信息的响应
      let httpRequest = http.createHttp();
      httpRequest.request(
        // 请替换为具体的sts临时密钥获取服务url
        "http://127.0.0.1/sts",
        { method: http.RequestMethod.GET },
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            const stsSessionQCloudCredentials: StsSessionQCloudCredentials = JSON.parse(data.result.toString());
            let credential : QCloudCredential= new QCloudCredential();
            credential.secretID = stsSessionQCloudCredentials.credentials.tmpSecretId;
            credential.secretKey = stsSessionQCloudCredentials.credentials.tmpSecretKey;
            credential.token = stsSessionQCloudCredentials.credentials.sessionToken;
            // 建议返回服务器时间作为签名的开始时间，避免由于用户手机本地时间偏差过大导致请求过期
            // startDate和expirationDate均为Date类型，此处通过毫秒时间戳构造Date，
            // sts响应的时间戳一般单位为秒，因此需要乘以1000，如果您的临时密钥服务响应的时间单位为毫秒，则无需乘以1000
            credential.startDate = new Date(stsSessionQCloudCredentials.startTime * 1000);
            credential.expirationDate = new Date(stsSessionQCloudCredentials.expiredTime * 1000);
            httpRequest.destroy();
            // 最后返回临时密钥信息对象
            resolve(credential)
          } else {
            httpRequest.destroy();
            reject(err)
          }
        });
    })
  }
}

/**
 * 临时秘钥实体定义
 */
export class StsSessionQCloudCredentials{
  credentials: StsCredentials;
  startTime: number;
  expiredTime: number;

  constructor(credentials: StsCredentials, startTime: number, expiredTime: number) {
    this.credentials = credentials;
    this.startTime = startTime;
    this.expiredTime = expiredTime;
  }
}
export class StsCredentials{
  tmpSecretId: string;
  tmpSecretKey: string;
  sessionToken: string;

  constructor(tmpSecretId: string, tmpSecretKey: string, sessionToken: string) {
    this.tmpSecretId = tmpSecretId;
    this.tmpSecretKey = tmpSecretKey;
    this.sessionToken = sessionToken;
  }
}
```

【服务端签名回调】

采用回调的方式给 COS SDK 提供获取签名的方法，SDK 会在发起网络请求时调用该方法，该方法内可以做签名相关逻辑。
``` typescript
    // 定义服务端签名回调
    let selfSignCallBack = async (request)=>{
      // 首先从您的服务器获取包含了签名信息的响应
      let httpRequest = http.createHttp();
      httpRequest.request(
        // 请替换为具体的签名获取服务url
        "http://127.0.0.1/sign",
        { method: http.RequestMethod.GET },
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            // 拿到签名信息
            let signData: object = JSON.parse(data.result.toString());
            // 对request进行签名header的设置
            request.addHeader(HttpHeader.AUTHORIZATION, signData['authorization'])
            if(signData['securityToken']){
              request.addHeader("x-cos-security-token", signData['securityToken'])
            }
            httpRequest.destroy();
          } else {
            httpRequest.destroy();
          }
      });
    }
```


【单次请求签名】

将单个请求签名设置给具体的 CosXmlRequest（例如上传的 PutObjectRequest等），该签名仅用于本次 COS 操作（例如上传等）。
``` typescript
// 获取签名数据（业务层控制获取的方式）
let authorization: string = "authorization";
let token: string = "token";
let tokenName: string = "x-cos-security-token";
```

【固定密钥（仅测试）】

您可以使用腾讯云的永久密钥来进行开发阶段的本地调试。**由于该方式存在泄露密钥的风险，请务必在上线前替换为临时密钥的方式。**
``` typescript
import { CredentialCallBack, QCloudCredential } from '@tencentcloud/cos';

export class Credential {
  /**
   * 获取固定秘钥 仅在测试时使用
   */
  public static constCredential: CredentialCallBack = (request)=>{
    return new Promise((resolve, reject) => {
      let credential : QCloudCredential= new QCloudCredential();

      // 用户的 SecretId，建议使用子账号密钥，授权遵循最小权限指引，降低使用风险。子账号密钥获取可参见 https://cloud.tencent.com/document/product/598/37140
      credential.secretID = "SECRETID";
      // 用户的 SecretKey，建议使用子账号密钥，授权遵循最小权限指引，降低使用风险。子账号密钥获取可参见 https://cloud.tencent.com/document/product/598/37140
      credential.secretKey = "SECRETKEY";
      resolve(credential)
    })
  }
}
```

### 2. 初始化 COS 服务

调用 CosXmlBaseService.initDefaultService 进行 COS 服务初始化之后就可以调用 CosXmlBaseService.default() 获取到默认的 COS 服务进行 COS 操作了。

COS 服务也支持自行实例化 CosXmlBaseService 进行 COS 操作（不过不建议每次 COS 操作都实例化一个 CosXmlBaseService）。


【单次临时密钥】

单次临时密钥的优先级高于 CosXmlBaseService 中初始化配置的临时密钥回调，因此 CosXmlBaseService 中配置的临时密钥回调不会影响单次临时秘钥的设置，直接给cosXmlRequest设置credential即可。
``` typescript
import { CosXmlBaseService, PutObjectRequest, UploadTask } from '@tencentcloud/cos';

// 任何CosXmlRequest都支持这种方式，例如上传PutObjectRequest、下载GetObjectRequest、删除DeleteObjectRequest等
// 以下用上传进行示例
let putRequest = new PutObjectRequest("examplebucket-1250000000", "exampleobject.txt", "本地文件路径");
// credential为第一步“初始化密钥”中获取到的单次临时密钥
putRequest.credential = credential;
let task: UploadTask = CosXmlBaseService.default().upload(putRequest);
task.start();
```


【临时密钥回调】

初始化默认的 Service。
``` typescript
import { CosXmlBaseService, CosXmlServiceConfig } from '@tencentcloud/cos';

// 服务配置
let cosXmlServiceConfig = new CosXmlServiceConfig("ap-guangzhou");
// 初始化默认的Service
CosXmlBaseService.initDefaultService(
  this.context.getApplicationContext(),
  cosXmlServiceConfig,
  // 第一步“初始化密钥”中获取到的临时密钥回调
  Credential.sessionCredential
)
```

【服务端签名回调】

初始化默认的 Service。
``` typescript
import { CosXmlBaseService, CosXmlServiceConfig } from '@tencentcloud/cos';

// 服务配置
let cosXmlServiceConfig = new CosXmlServiceConfig("ap-guangzhou");
// 初始化默认的Service
CosXmlBaseService.initDefaultService(
  this.context.getApplicationContext(),
  cosXmlServiceConfig
)
// 第一步“初始化密钥”中获取到的服务端签名回调
CosXmlBaseService.default().setSelfSignCallBack(selfSignCallBack);
```


【单次请求签名】

单次请求签名的优先级高于密钥进行的签名，因此设置的密钥不会影响单次请求签名的设置，直接给cosXmlRequest通过setSign设置签名即可。
``` typescript
import { CosXmlBaseService, PutObjectRequest, UploadTask } from '@tencentcloud/cos';

// 任何CosXmlRequest都支持这种方式，例如上传PutObjectRequest、下载GetObjectRequest、删除DeleteObjectRequest等
// 以下用上传进行示例
let putRequest = new PutObjectRequest("examplebucket-1250000000", "exampleobject.txt", "本地文件路径");
// authorization、token、tokenName为第一步“初始化密钥”中获取到的单次签名信息
putRequest.setSign(authorization, stoken, tokenName);
let task: UploadTask = CosXmlBaseService.default().upload(putRequest);
task.start();
```

【固定密钥（仅测试）】

初始化默认的 Service。
``` typescript
import { CosXmlBaseService, CosXmlServiceConfig } from '@tencentcloud/cos';

// 服务配置
let cosXmlServiceConfig = new CosXmlServiceConfig("ap-guangzhou");
// 初始化默认的Service
CosXmlBaseService.initDefaultService(
  this.context.getApplicationContext(),
  cosXmlServiceConfig,
  // 第一步“初始化密钥”中获取到的固定密钥回调
  Credential.constCredential
)
```

#### 参数说明

CosXmlServiceConfig 用于配置 COS 服务，其主要成员说明如下：
<table>
<tr>
<td rowspan="1" colSpan="1" >参数名称</td>

<td rowspan="1" colSpan="1" >描述</td>

<td rowspan="1" colSpan="1" >类型</td>

<td rowspan="1" colSpan="1" >默认值</td>

<td rowspan="1" colSpan="1" >必选</td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >region</td>

<td rowspan="1" colSpan="1" >存储桶地域 [地域和访问域名](https://cloud.tencent.com/document/product/436/6224)</td>

<td rowspan="1" colSpan="1" >string</td>

<td rowspan="1" colSpan="1" >无</td>

<td rowspan="1" colSpan="1" >否（和host二选一）</td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >protocol</td>

<td rowspan="1" colSpan="1" >网络协议：https、http</td>

<td rowspan="1" colSpan="1" >string</td>

<td rowspan="1" colSpan="1" >https</td>

<td rowspan="1" colSpan="1" >否</td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >connectTimeout</td>

<td rowspan="1" colSpan="1" >连接超时时间（单位是毫秒）</td>

<td rowspan="1" colSpan="1" >number</td>

<td rowspan="1" colSpan="1" >15 * 1000</td>

<td rowspan="1" colSpan="1" >否</td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >readTimeout</td>

<td rowspan="1" colSpan="1" >读取超时时间（单位是毫秒）</td>

<td rowspan="1" colSpan="1" >number</td>

<td rowspan="1" colSpan="1" >30 * 1000</td>

<td rowspan="1" colSpan="1" >否</td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >host</td>

<td rowspan="1" colSpan="1" >自定义域名，sdk 会将 ${bucket} 替换为真正的 bucket，${region} 替换为真正的 region<br>例如将 host 设置为  ${bucket}.${region}.tencent.com，并且您的存储桶和地域分别为 bucket-1250000000 和 ap-shanghai，那么最终的请求地址为 <br>bucket-1250000000.ap-shanghai.tencent.com</td>

<td rowspan="1" colSpan="1" >string</td>

<td rowspan="1" colSpan="1" >${bucket}.cos.${region}.myqcloud.com</td>

<td rowspan="1" colSpan="1" >否（和region二选一）</td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >port</td>

<td rowspan="1" colSpan="1" >设置请求的端口</td>

<td rowspan="1" colSpan="1" >number</td>

<td rowspan="1" colSpan="1" >无</td>

<td rowspan="1" colSpan="1" >否</td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >headers</td>

<td rowspan="1" colSpan="1" >设置公共header</td>

<td rowspan="1" colSpan="1" >Map<string, string></td>

<td rowspan="1" colSpan="1" >无</td>

<td rowspan="1" colSpan="1" >否</td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >noSignHeaderKeys</td>

<td rowspan="1" colSpan="1" >设置不签名的header</td>

<td rowspan="1" colSpan="1" >Set<string></td>

<td rowspan="1" colSpan="1" >无</td>

<td rowspan="1" colSpan="1" >否</td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >uploadMaxConcurrentCount</td>

<td rowspan="1" colSpan="1" >上传任务并发数</td>

<td rowspan="1" colSpan="1" >number</td>

<td rowspan="1" colSpan="1" >4</td>

<td rowspan="1" colSpan="1" >否</td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >downloadMaxConcurrentCount</td>

<td rowspan="1" colSpan="1" >下载任务并发数</td>

<td rowspan="1" colSpan="1" >number</td>

<td rowspan="1" colSpan="1" >4</td>

<td rowspan="1" colSpan="1" >否</td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >maxRetryCount</td>

<td rowspan="1" colSpan="1" >重试最大次数</td>

<td rowspan="1" colSpan="1" >number</td>

<td rowspan="1" colSpan="1" >3</td>

<td rowspan="1" colSpan="1" >否</td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >retrySleep</td>

<td rowspan="1" colSpan="1" >重试间隔时间，单位：毫秒</td>

<td rowspan="1" colSpan="1" >number</td>

<td rowspan="1" colSpan="1" >1000</td>

<td rowspan="1" colSpan="1" >否</td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >dnsOverHttps</td>

<td rowspan="1" colSpan="1" >设置使用https协议的服务器进行DNS解析</td>

<td rowspan="1" colSpan="1" >string</td>

<td rowspan="1" colSpan="1" >无</td>

<td rowspan="1" colSpan="1" >否</td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >dnsServers</td>

<td rowspan="1" colSpan="1" >设置指定的DNS服务器进行DNS解析，最多3个</td>

<td rowspan="1" colSpan="1" >Array<string></td>

<td rowspan="1" colSpan="1" >无</td>

<td rowspan="1" colSpan="1" >否</td>
</tr>
</table>


## 第三步：访问 COS 服务

### 上传对象
``` typescript
import { CosXmlBaseService, HttpProgress, PutObjectRequest, UploadTask, TransferConfig, CosXmlUploadTaskResult, CosError } from '@tencentcloud/cos';

// 存储桶名称，由 bucketname-appid 组成，appid 必须填入，可以在 COS 控制台查看存储桶名称。 https://console.cloud.tencent.com/cos5/bucket
let bucket = "examplebucket-1250000000";
//对象在存储桶中的位置标识符，即称对象键
let cosPath = "exampleobject.txt"; 
//本地文件路径
let srcPath = "本地文件路径"; 
//若存在初始化分块上传的 UploadId，则赋值对应的 _uploadId 值用于续传；否则，赋值 undefined
let _uploadId: string | undefined = undefined;
// 上传配置
let transferConfig = new TransferConfig();

let putRequest = new PutObjectRequest(bucket, cosPath, srcPath);
let task: UploadTask = CosXmlBaseService.default().upload(putRequest, _uploadId, transferConfig);
// 上传进度回调
task.onProgress = (progress: HttpProgress) => {
  // progress.complete为当前已上传大小
  // progress.target为总大小
};
task.onResult = {
  // 上传成功回调
  onSuccess: (request, result: CosXmlUploadTaskResult) => {
    // todo 上传成功后的逻辑
  },
  //上传失败回调
  onFail: (request, error: CosError) => {
    // todo 上传失败后的逻辑
  }
}
//初始化完成回调
task.initCallBack = (uploadId) =>{
  //用于下次续传上传的 uploadId
  _uploadId = uploadId;
}
//开始上传
task.start();
//暂停任务
// task.pause();
//恢复任务
// task.resume();
//取消任务
// task.cancel();
```

TransferConfig 用于配置 COS 上传服务，其主要成员说明如下：
<table>
<tr>
<td rowspan="1" colSpan="1" >参数名称</td>

<td rowspan="1" colSpan="1" >描述</td>

<td rowspan="1" colSpan="1" >类型</td>

<td rowspan="1" colSpan="1" >默认值</td>

<td rowspan="1" colSpan="1" >必选</td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >simpleUploadLimit</td>

<td rowspan="1" colSpan="1" >简单上传限制，文件大小小于该值，使用简单上传，大于等于则使用分块上传</td>

<td rowspan="1" colSpan="1" >number</td>

<td rowspan="1" colSpan="1" >1 * 1024 * 1024</td>

<td rowspan="1" colSpan="1" >否</td>
</tr>

<tr>
<td rowspan="1" colSpan="1" >sliceLength</td>

<td rowspan="1" colSpan="1" >设置分块上传时每个分块的大小</td>

<td rowspan="1" colSpan="1" >number</td>

<td rowspan="1" colSpan="1" >1 * 1024 * 1024</td>

<td rowspan="1" colSpan="1" >否</td>
</tr>
</table>


#### 授权说明

在您进行 [授权策略](https://cloud.tencent.com/document/product/436/31923) 时，action 请参考如下示例。
``` bash
{
  "version": "2.0",
  "statement": [
    {
      "action": [
                //head操作 
                "name/cos:HeadObject",
                //简单上传操作 
                "name/cos:PutObject",
                //分块上传：初始化分块操作 
                "name/cos:InitiateMultipartUpload",
                //分块上传：List 已上传分块操作 
                "name/cos:ListParts",
                //分块上传：上传分块操作 
                "name/cos:UploadPart",
                //分块上传：完成所有分块上传操作 
                "name/cos:CompleteMultipartUpload",
                //取消分块上传操作 
                "name/cos:AbortMultipartUpload"
      ],
      "effect": "allow",
      "resource": [
        "qcs::cos:ap-beijing:uid/1250000000:examplebucket-1250000000/doc/*"
      ]
    }
  ]
}
```

对象存储的更多 action，请参见 [支持CAM的业务接口](https://cloud.tencent.com/document/product/598/69901)。

### 下载对象

高级接口支持暂停、恢复以及取消下载请求，同时支持断点下载功能。

您只需要保证 bucket、cosPath、savePath参数一致，SDK 便会从上次已经下载的位置继续下载。
``` typescript
import { CosXmlBaseService, HttpProgress, GetObjectRequest, DownloadTask, CosXmlDownloadTaskResult, CosError } from '@tencentcloud/cos';

// 存储桶名称，由 bucketname-appid 组成，appid 必须填入，可以在 COS 控制台查看存储桶名称。 https://console.cloud.tencent.com/cos5/bucket
let bucket = "examplebucket-1250000000";
//对象在存储桶中的位置标识符，即称对象键
let cosPath = "exampleobject.txt"; 
//本地文件下载路径，如果文件不存在sdk会自动创建
let downliadPath = "本地文件路径"; 

let getRequest = new GetObjectRequest(bucket, cosPath, downliadPath);
let task: DownloadTask = CosXmlBaseService.default().download(getRequest);
// 下载进度回调
task.onProgress = (progress: HttpProgress) => {
  // progress.complete为当前已下载大小
  // progress.target为总大小
};
task.onResult = {
  // 下载成功回调
  onSuccess: (request, result: CosXmlDownloadTaskResult) => {
    // todo 下载成功后的逻辑
  },
  //下载失败回调
  onFail: (request, error: CosError) => {
    // todo 下载失败后的逻辑
  }
}
//开始下载
task.start();
//暂停任务
// task.pause();
//恢复任务
// task.resume();
//取消任务
// task.cancel();
```

#### 授权说明

在您进行 [授权策略](https://cloud.tencent.com/document/product/436/31923) 时，action 请参考如下示例。
``` bash
{
  "version": "2.0",
  "statement": [
    {
      "action": [
                //head操作 
                "name/cos:HeadObject",
                //下载操作
                "name/cos:GetObject",
      ],
      "effect": "allow",
      "resource": [
        "qcs::cos:ap-beijing:uid/1250000000:examplebucket-1250000000/doc/*"
      ]
    }
  ]
}
```

对象存储的更多 action，请参见 [支持CAM的业务接口](https://cloud.tencent.com/document/product/598/69901)。

> **说明：**
> 

> 高级下载接口支持断点续传，所以会在下载前先发起 HEAD 请求获取文件信息。如果您使用的是临时密钥或者使用子账号访问，请确保权限列表中包含 HeadObject 的权限。
> 


