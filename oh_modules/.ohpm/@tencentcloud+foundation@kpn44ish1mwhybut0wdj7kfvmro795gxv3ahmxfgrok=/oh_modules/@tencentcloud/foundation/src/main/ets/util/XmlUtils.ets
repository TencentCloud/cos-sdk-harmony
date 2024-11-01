import convertxml from '@ohos.convertxml';
import xml from '@ohos.xml';
import util from '@ohos.util';
import { List } from '@kit.ArkTS';
import { QCloudLogger } from '../logger/QCloudLogger';

export class XmlUtils {

  static lowerCamel(name:string){
    let tempName = name;
    if (tempName.length > 0) {
      let first = tempName.substring(0, 1);
      tempName = first.toLowerCase() + tempName.substring(1);
    }
    return tempName;
  }

  static upperCamel(name:string){
    let tempName = name;
    if (tempName.length > 0) {
      let first = tempName.substring(0, 1);
      tempName = first.toUpperCase() + tempName.substring(1);
    }
    return tempName;
  }

  static obj2xml(obj:object,upperlCamel?:boolean):string|null{
    if (Array.isArray(obj)) {
      QCloudLogger.warn("Array type does not support conversion to xml");
      return null
    }

    try {
      let arrayBuffer: ArrayBuffer = new ArrayBuffer(JSON.stringify(obj).length * 2); // 创建一个2048字节的缓冲区
      let thatSer: xml.XmlSerializer = new xml.XmlSerializer(arrayBuffer); // 基于Arraybuffer构造XmlSerializer对象

      thatSer = XmlUtils.createXmlElement('',obj,thatSer,upperlCamel||true);

      let view: Uint8Array = new Uint8Array(arrayBuffer); // 使用Uint8Array读取arrayBuffer的数据
      let textDecoder: util.TextDecoder = util.TextDecoder.create(); // 调用util模块的TextDecoder类
      let res: string = textDecoder.decodeWithStream(view).trim(); // 对view解码
      return res
    } catch (e) {
      return null
    }
  }

  private static createXmlElement(key:string,obj: object,thatSer:xml.XmlSerializer,upperlCamel:boolean): xml.XmlSerializer{

    if (typeof obj == 'string') {
      thatSer.setText(obj);
    }else if (typeof obj == 'number') {
      let num:number = obj;
      thatSer.setText(num.toString());
    }else if (typeof obj == 'boolean') {
      let num:boolean = obj;
      thatSer.setText(num?'true':'false');
    }else if (obj instanceof List) {
      let array:List<object> = obj;
      for (const item of array) {
        key = upperlCamel?XmlUtils.upperCamel(key):key;
        thatSer.startElement(key);
        thatSer = XmlUtils.createXmlElement(key,item,thatSer,upperlCamel);
        thatSer.endElement();
      }
    }else{
      for (const _itemKey of Object.keys(obj)) {
        let _key = upperlCamel?XmlUtils.upperCamel(_itemKey):_itemKey;
        let value:object = obj[_itemKey];
        if (value) {
          if (value instanceof List ||value instanceof Array ){
            thatSer = XmlUtils.createXmlElement(_key,value,thatSer,upperlCamel);
          }else{
            thatSer.startElement(_key);
            thatSer = XmlUtils.createXmlElement(_key,value,thatSer,upperlCamel);
            thatSer.endElement();
          }
        }else{
          thatSer.startElement(_key);
          thatSer.endElement();
        }
      }
    }

    return thatSer;
  }

  static xml2obj(xml: string,lCamel?:boolean): object|null {
    try {
      let conv = new convertxml.ConvertXML()
      let result: object = conv.convertToJSObject(xml);
      let model = XmlUtils.getElementValue(result['_elements'][0],null,true,lCamel||true);
      return model;
    } catch (e) {
      return null;
    }
  }

  private static getElementValue(element: object,pObj:object|null,root:boolean,lCamel:boolean): object|null {
    let name:string = element['_name'];
    if (name) {
      name = lCamel?XmlUtils.lowerCamel(name):name;
    }
    let type: string = element['_type'];
    if (type == 'text') {
      return element['_text'];
    }

    if (!Object.keys(element).includes('_elements')) {
      return null;
    }

    let elements:List<object> = element['_elements'];
    let obj = pObj;
    if (!obj) {
      obj = new Object();
    }

    if (type == 'element') {
      for (const _element of elements) {
        let _name: string = _element['_name'];
        if (!_name) {
          let value= XmlUtils.getElementValue(_element,obj,false,lCamel);
          if (!root) {
            return value;
          }
          obj[name] = value;
          return obj;
        }else{
          _name = lCamel?XmlUtils.lowerCamel(_name):_name;
          let value= XmlUtils.getElementValue(_element,null,false,lCamel);
          if (value) {
            if (obj[_name]) {
              if (Array.isArray(obj[_name]) || obj[_name] instanceof List) {
                let array:List<object> = obj[_name];
                array.add(value);
                obj[_name] = array;
              }else{
                let array = new List<object>();
                array.add(obj[_name]);
                array.add(value);
                obj[_name] = array;
              }
            }else{
              obj[_name] = value;
            }
          }else{
            obj[_name] = null;
          }
        }
      }
    }

    if (root) {
      let rObj:object = new Object();
      rObj[name] = obj;
      return rObj;
    }
    return obj;
  }
}
