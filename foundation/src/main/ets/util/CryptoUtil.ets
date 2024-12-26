import cryptoFramework from '@ohos.security.cryptoFramework';
import buffer from '@ohos.buffer';
import { StringUtils } from './StringUtils';

export class CryptoUtil{

  static async qlcoudSha1(str:string):Promise<string>{
    return CryptoUtil.qlcoudSha1Uint8Array(new Uint8Array(buffer.from(str, 'utf-8').buffer))
  }

  static async qlcoudSha1Uint8Array(array:Uint8Array):Promise<string>{
    let mdAlgName = "SHA1"; // 摘要算法名
    let md = cryptoFramework.createMd(mdAlgName);
    // 假设信息总共43字节，根据utf-8解码后，也是43字节
    let messageData = array;
    let updateLength = 20; // 假设以20字节为单位进行分段update，实际并无要求
    for (let i = 0; i < messageData.length; i += updateLength) {
      let updateMessage = messageData.subarray(i, i + updateLength);
      let updateMessageBlob: cryptoFramework.DataBlob = { data: updateMessage };
      await md.update(updateMessageBlob);
    }
    let mdOutput = await md.digest();
    return StringUtils.uint8Array2String(mdOutput.data);
  }

  static async qcloudHmacSha1(str:string,secret:string):Promise<string> {
    return CryptoUtil.qcloudHmacSha1Uint8Array(new Uint8Array(buffer.from(str, 'utf-8').buffer),secret);
  }

  static async qcloudHmacSha1Uint8Array(array:Uint8Array,secret:string):Promise<string> {
    let keyData = new Uint8Array(buffer.from(secret, 'utf-8').buffer);
    let symKeyBlob: cryptoFramework.DataBlob = { data: keyData };
    let aesGenerator = cryptoFramework.createSymKeyGenerator('HMAC');
    let key = await aesGenerator.convertKey(symKeyBlob);
    let macAlgName = "SHA1"; // 摘要算法名
    let mac = cryptoFramework.createMac(macAlgName);
    let messageData = array;
    let updateLength = 1024 * 1024; // 假设以20字节为单位进行分段update，实际并无要求
    await mac.init(key);
    for (let i = 0; i < messageData.length; i += updateLength) {
      let updateMessage = messageData.subarray(i, i + updateLength);
      let updateMessageBlob: cryptoFramework.DataBlob = { data: updateMessage };
      await mac.update(updateMessageBlob);
    }
    let macOutput = await mac.doFinal();
    return StringUtils.uint8Array2String(macOutput.data);
  }

  static async qcloudMd5String(str:string):Promise<string> {
    return CryptoUtil.qcloudMd5ArrayBuffer(buffer.from(str, 'utf-8').buffer);
  }

  static async qcloudMd5ArrayBuffer(array:ArrayBuffer):Promise<string> {
    let mdAlgName = "MD5"; // 摘要算法名
    let md = cryptoFramework.createMd(mdAlgName);
    let _buffer = new Uint8Array(array);
    // 假设信息总共43字节，根据utf-8解码后，也是43字节
    let messageData = _buffer;
    let updateLength = 1024 * 1024; // 假设以20字节为单位进行分段update，实际并无要求
    for (let i = 0; i < messageData.length; i += updateLength) {
      let updateMessage = messageData.subarray(i, i + updateLength);
      let updateMessageBlob: cryptoFramework.DataBlob = { data: updateMessage };
      await md.update(updateMessageBlob);
    }
    let mdOutput = await md.digest();
    let buffer1 = buffer.from(mdOutput.data);
    return buffer1.toString("base64");
  }
}