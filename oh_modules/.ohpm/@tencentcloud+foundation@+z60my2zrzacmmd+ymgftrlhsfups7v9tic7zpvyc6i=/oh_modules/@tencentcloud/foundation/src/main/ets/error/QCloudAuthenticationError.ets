/**
 * 凭证验证error
 */
export class QCloudAuthenticationError extends Error {
  public error: object;
  constructor(error: object) {
    super();
    this.error = error;
  }
}