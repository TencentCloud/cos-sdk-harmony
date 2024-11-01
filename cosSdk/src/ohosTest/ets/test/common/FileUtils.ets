import { abilityDelegatorRegistry } from '@kit.TestKit';
import fs, { ReadOptions } from '@ohos.file.fs';

export class FileUtils{
  public static getContext(): Context {
    let abilityDelegator = abilityDelegatorRegistry.getAbilityDelegator();
    return abilityDelegator.getAppContext().getApplicationContext();
  }

  public static getFile(size:number,name:string):string{
    let pathDir = FileUtils.getContext().tempDir;
    let filePath = pathDir + `/${name}tempFile`;
    let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    let buffer:ArrayBuffer = new ArrayBuffer(size);
    let writeLen = fs.writeSync(file.fd, buffer);
    console.info("write data to file succeed and size is:" + writeLen);
    fs.closeSync(file);
    return filePath;
  }
}
