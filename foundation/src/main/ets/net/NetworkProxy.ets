import { CustomNetworkRequest } from './CustomNetworkRequest';
import { CustomNetworkResponseHandler } from './CustomNetworkResponseHandler';

/**
 * 网络执行代理：承载「单次」网络请求的执行与取消。
 *
 * 每次请求（含重试的每一次）由 {@link NetworkClient#getNetworkProxy} 产出一个新的实例，
 * 因此实现类可以在实例上安全地持有当次请求的句柄（用于 {@link cancel}）。
 *
 * 自定义网络层需要继承本类并实现 {@link executeHttpRequest} 与 {@link cancel}。
 * 参考默认实现 HarmonyNetworkProxy。
 */
export abstract class NetworkProxy {
  /**
   * 执行一次网络请求。
   *
   * 实现方使用自己的网络栈按 {@link CustomNetworkRequest} 发起请求，
   * 并在请求过程中通过 {@link handler} 回调响应头、数据分片、进度、结束或失败。
   *
   * @param request 请求数据（已签名、已构建完成）
   * @param handler 响应回调，由框架提供
   */
  abstract executeHttpRequest(request: CustomNetworkRequest, handler: CustomNetworkResponseHandler): void;

  /**
   * 取消当前正在执行的请求。
   */
  abstract cancel(): void;
}
