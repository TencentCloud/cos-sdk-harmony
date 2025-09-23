export class HttpUtils{
  public static parseContentRange(contentRange: string|undefined): number[] | undefined {
    if (!contentRange) {
      return undefined;
    }
    const lastBlankIndex = contentRange.lastIndexOf(" ");
    const acrossIndex = contentRange.indexOf("-");
    const slashIndex = contentRange.indexOf("/");
    if (lastBlankIndex === -1 || acrossIndex === -1 || slashIndex === -1) {
      return undefined;
    }

    const start = Number(contentRange.substring(lastBlankIndex + 1, acrossIndex));
    const end = Number(contentRange.substring(acrossIndex + 1, slashIndex));
    const max = Number(contentRange.substring(slashIndex + 1));

    return [start, end, max];
  }
}