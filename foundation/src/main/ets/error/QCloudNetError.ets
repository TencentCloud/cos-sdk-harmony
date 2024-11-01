/**
 * 网络error
 */
export class QCloudNetError extends Error {
  public netError: object;
  constructor(netError: object) {
    super();
    this.netError = netError;
  }
}
