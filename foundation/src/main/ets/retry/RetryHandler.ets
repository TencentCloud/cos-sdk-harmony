export class RetryHandler{
  private currentTryCount:number = 0;
  maxCount:number = 0;
  sleep:number = 0;
  // 标记是否已执行过域名切换
  private hostSwitched:boolean = false;

  static defaultHandler(){
    return new RetryHandler(3,1);
  }

  constructor(count:number,sleep:number) {
    this.maxCount = count;
    this.sleep = sleep;
  }

  reset(){
    this.currentTryCount = 0;
    this.hostSwitched = false;
  }

  currentCount(){
    return this.currentTryCount;
  }

  shouldRetry():boolean{
    if (this.currentTryCount>=this.maxCount){
      return false;
    }
    return true;
  }

  retry(){
    this.currentTryCount ++;
  }

  /**
   * 标记为最后一次重试机会（用于3XX）
   */
  markMaxCount(){
    this.currentTryCount = this.maxCount;
  }

  /**
   * 判断是否为最后一次重试机会
   * @returns 如果当前重试次数等于最大重试次数减1，返回true
   */
  isLastRetry():boolean{
    return this.currentTryCount >= this.maxCount - 1;
  }

  /**
   * 设置域名切换标记
   */
  markHostSwitched(){
    this.hostSwitched = true;
  }

  /**
   * 获取域名切换状态
   * @returns 是否已执行过域名切换
   */
  isHostSwitched():boolean{
    return this.hostSwitched;
  }

  copy():RetryHandler{
    return new RetryHandler(this.maxCount,this.sleep);
  }
}