/**
 * 任务error
 */
export class QCloudTaskError extends Error {
  public taskError: object;
  constructor(taskError: object) {
    super();
    this.taskError = taskError;
  }
}
