import { ObjectRequest } from './ObjectRequest';
import http from '@ohos.net.http';
import { ContentType, RequestBodySerializer, XmlUtils } from '@tencentcloud/foundation';

/**
 * POST Object restore 接口请求可以对一个归档存储或深度归档存储类型的对象进行恢复（解冻）以便读取该对象内容，
 * 恢复出的可读取对象是临时的，您可以设置需要保持可读以及随后删除该临时副本的时间。
 *
 * 本接口同时可以用于恢复智能分层存储归档层或深度归档层对象，恢复后智能分层对象将直接回到标准层，
 * 不会产生临时副本及副本存储费用。
 *
 * 关于恢复归档对象的具体描述，请查看 https://cloud.tencent.com/document/product/436/12633
 */
export class RestoreObjectRequest extends ObjectRequest {
  /**
   * 对于普通的归档存储和深度归档存储对象，需要指定恢复出的临时副本的有效时长，取值范围为1 - 365，单位为"天"。
   * 如果是智能分层归档层或深度归档层对象，不需要指定此参数。
   */
  days?: number;

  /**
   * 恢复模式，可选值：
   * - Expedited：快速取回模式，恢复任务在1 - 5分钟内可完成（仅归档存储/智能分层归档层）。
   * - Standard：标准取回模式，归档存储恢复任务在3 - 5小时内完成，深度归档存储恢复时间为12 - 24小时。
   * - Bulk：批量取回模式，归档存储恢复任务在5 - 12小时内完成，深度归档存储恢复时间为24 - 48小时。
   *
   * 如果不指定恢复模式，默认使用 Standard 标准取回模式恢复。
   */
  tier?: string;

  /**
   * 当启用版本控制时，指定要恢复的版本 ID，如不指定则恢复对象的最新版本。
   */
  versionId?: string;

  constructor(bucket: string, cosPath: string) {
    super(bucket, cosPath);
    this.isNeedMD5 = true;
  }

  public getQueries(): Map<string, string | undefined> {
    this.addQuery('restore', undefined);
    if (this.versionId) {
      this.addQuery('versionId', this.versionId);
    }
    return this.queries;
  }

  public getBodySerializer(): RequestBodySerializer | undefined {
    let restoreRequest: object = new Object();
    if (this.days !== undefined) {
      restoreRequest["days"] = this.days;
    }
    if (this.tier) {
      let casJobParameters: object = new Object();
      casJobParameters["tier"] = this.tier;
      restoreRequest["cASJobParameters"] = casJobParameters;
    }
    let input: object = new Object();
    input["restoreRequest"] = restoreRequest;
    let bodyString = XmlUtils.obj2xml(input, true) || "";
    return RequestBodySerializer.wrap(ContentType.XML, bodyString);
  }

  public getMethod(): http.RequestMethod {
    return http.RequestMethod.POST;
  }
}
