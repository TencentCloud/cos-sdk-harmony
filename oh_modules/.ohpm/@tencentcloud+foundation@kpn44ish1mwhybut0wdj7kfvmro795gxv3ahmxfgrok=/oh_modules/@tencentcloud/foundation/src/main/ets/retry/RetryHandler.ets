export class RetryHandler{
  private currentTryCount:number = 0;
  maxCount:number = 0;
  sleep:number = 0;

  static defaultHandler(){
    return new RetryHandler(3,1);
  }

  constructor(count:number,sleep:number) {
    this.maxCount = count;
    this.sleep = sleep;
  }

  reset(){
    this.currentTryCount = 0;
  }

  shouldRetry():boolean{
    if (this.currentTryCount>=this.maxCount){
      return false;
    }
    this.currentTryCount ++;
    return true;
  }

  copy():RetryHandler{
     return new RetryHandler(this.maxCount,this.sleep);
  }
}