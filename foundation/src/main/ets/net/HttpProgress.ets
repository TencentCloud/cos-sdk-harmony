export class HttpProgress{
  public complete:number;
  public target:number;

  constructor(complete: number, target: number) {
    this.complete = complete;
    this.target = target;
  }

}

/**
 * 进度控制器,目前用于频控
 */
export class ProgressController {
  private lastUpdateTime = 0;
  private timeGranularity: number | undefined;
  private onProgress: Callback<HttpProgress> | undefined;

  // 时间颗粒度默认为200ms
  constructor(onProgress: Callback<HttpProgress> | undefined, timeGranularity: number | undefined) {
    this.onProgress = onProgress;
    this.timeGranularity = timeGranularity;
  }

  public updateProgress(complete: number, target: number) {
    if(this.timeGranularity) {
      const now = Date.now();
      const progress = (complete / target) * 100;
      if (progress >= 100 || now - this.lastUpdateTime >= this.timeGranularity) {
        this.lastUpdateTime = now;
        if (this.onProgress) {
          this.onProgress(new HttpProgress(complete, target));
        }
      }
    } else {
      if (this.onProgress) {
        this.onProgress(new HttpProgress(complete, target));
      }
    }
  }
}