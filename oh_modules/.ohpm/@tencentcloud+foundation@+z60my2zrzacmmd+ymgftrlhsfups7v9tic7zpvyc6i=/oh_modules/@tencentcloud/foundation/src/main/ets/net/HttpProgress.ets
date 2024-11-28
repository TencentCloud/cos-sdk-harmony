export class HttpProgress{
  public complete:number;
  public target:number;

  constructor(complete: number, target: number) {
    this.complete = complete;
    this.target = target;
  }

}