import fs, { ReadOptions } from '@ohos.file.fs';

export class CRC64 {
  public static generateTable() {
    // https://en.wikipedia.org/wiki/Cyclic_redundancy_check
    const POLY = BigInt("0xc96c5795d7870f42");
    const table: bigint[][] = [];

    for (let i = 0; i < 8; i++) {
      table[i] = [];
    }

    let crc = BigInt("0");

    for (let i = 0; i < 256; i++) {
      crc = BigInt(i);

      for (let j = 0; j < 8; j++) {
        if (crc & BigInt("1")) {
          crc = POLY ^ (crc >> BigInt("1"));
        } else {
          crc = crc >> BigInt("1");
        }
      }

      table[0][i] = crc;
    }

    for (let i = 0; i < 256; i++) {
      crc = table[0][i];

      for (let j = 1; j < 8; j++) {
        const index = Number(crc & BigInt("0xff"));
        crc = table[0][index] ^ (crc >> BigInt("8"));
        table[j][i] = crc;
      }
    }

    return table;
  }

  public static TABLE = CRC64.generateTable();

  public static async crc64(bytes: Uint8Array, previousCrc: bigint = ~BigInt(0) & BigInt("0xffffffffffffffff")): Promise<bigint> {
    return new Promise((resolve, reject) => {
      try {
        let crc = previousCrc;
        let index = 0;

        while (bytes.length - index > 8) {
          crc ^=
          BigInt(bytes[index]) |
            (BigInt(bytes[index + 1]) << BigInt("8")) |
            (BigInt(bytes[index + 2]) << BigInt("16")) |
            (BigInt(bytes[index + 3]) << BigInt("24")) |
            (BigInt(bytes[index + 4]) << BigInt("32")) |
            (BigInt(bytes[index + 5]) << BigInt("40")) |
            (BigInt(bytes[index + 6]) << BigInt("48")) |
            (BigInt(bytes[index + 7]) << BigInt("56"));

          crc =
            CRC64.TABLE[7][Number(crc & BigInt("0xff"))] ^
            CRC64.TABLE[6][Number((crc >> BigInt("8")) &  BigInt("0xff"))] ^
            CRC64.TABLE[5][Number((crc >> BigInt("16")) & BigInt("0xff"))] ^
            CRC64.TABLE[4][Number((crc >> BigInt("24")) & BigInt("0xff"))] ^
            CRC64.TABLE[3][Number((crc >> BigInt("32")) & BigInt("0xff"))] ^
            CRC64.TABLE[2][Number((crc >> BigInt("40")) & BigInt("0xff"))] ^
            CRC64.TABLE[1][Number((crc >> BigInt("48")) & BigInt("0xff"))] ^
            CRC64.TABLE[0][Number(crc >> BigInt("56"))];

          index += 8;
        }

        for (let i = index; i < bytes.length; i++) {
          const lower = Number(crc & BigInt("0xff"));
          const idx = lower ^ bytes[i];
          crc = CRC64.TABLE[0][idx] ^ (crc >> BigInt("8"));
        }
        resolve(crc);
      } catch (error) {
        reject(error);
      }
    });
  }

  /**
   * 计算文件的crc64
   * 每M需要2s 时间较长 大文件计算会比较慢
   */
  public static async crc64File(filePath: string, chunkSize: number = 1024 * 1024): Promise<bigint> {
    let file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
    let state = await fs.stat(file.fd);
    let fileSize = state.size;
    let offset = 0;
    let crc = ~BigInt(0) & BigInt("0xffffffffffffffff");

    // 创建一个固定大小的ArrayBuffer
    let arrayBuffer = new ArrayBuffer(chunkSize);
    // 创建一个映射到arrayBuffer的Uint8Array
    let bytes = new Uint8Array(arrayBuffer);

    while (offset < fileSize) {
      let length = Math.min(chunkSize, fileSize - offset);
      let option: ReadOptions = {
        offset: offset,
        length: length
      };
      await fs.read(file.fd, arrayBuffer, option);
      // 1024*1204需要耗时2s 时间较长 大文件计算会比较慢
      crc = await CRC64.crc64(bytes.slice(0, length), crc); // 只处理实际读取的部分
      offset += length;
    }

    await fs.close(file);

    crc = ~crc & BigInt("0xffffffffffffffff");
    return crc;
  }
}