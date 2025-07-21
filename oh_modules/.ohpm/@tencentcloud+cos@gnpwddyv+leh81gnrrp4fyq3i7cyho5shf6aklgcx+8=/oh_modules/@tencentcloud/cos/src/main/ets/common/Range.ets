export class Range {
  start: number;
  end: number;

  constructor(start: number, end: number = -1) {
    this.start = start;
    this.end = end;
  }

  getRange(): string {
    return `bytes=${this.start}-${this.end === -1 ? '' : this.end.toString()}`;
  }
}