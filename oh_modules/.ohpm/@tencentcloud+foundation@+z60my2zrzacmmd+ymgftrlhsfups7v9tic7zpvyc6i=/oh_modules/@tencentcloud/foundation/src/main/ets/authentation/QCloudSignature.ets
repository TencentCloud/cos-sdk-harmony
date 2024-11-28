/**
 访问腾讯云的服务需要对请求进行签名，以确定访问的用户身份，同时也保障访问的安全性。该类为腾讯云签名的抽象类。他代表了一个用于访问腾讯云服务的签名信息。
 需要您注意的是，签名信息是有有效期的。而您在创建签名信息的时候，也请您赋值相应的有效期。
 这个有效期在您进行签名的时候已经指定了，请确保此处的有效期和您进行签名的时候保持一致。否则将会产生不能访问腾讯云服务的问题。
 */

export class QCloudSignature{


  token?:string;

  tokenName?:string;
  /**
   签名字符串，经过签名算法计算之后的字符串。
   */
  authorization?:string;

  constructor(authorization?:string,token?:string) {
    this.authorization = authorization;
    this.token = token;
  }
}