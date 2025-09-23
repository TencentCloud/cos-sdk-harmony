/**
 * 用户取消error
 */
export class QCloudUserCancelError extends Error {
  constructor() {
    super("user cancel");
  }
}
