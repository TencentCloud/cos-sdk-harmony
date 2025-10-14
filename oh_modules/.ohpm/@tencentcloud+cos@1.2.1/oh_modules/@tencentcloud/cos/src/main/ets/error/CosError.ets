/**
 * 基类error
 */
import { CosErrorCode } from './CosErrorCode';

export abstract class CosError extends Error {
  public type: CosErrorType;
  public cosErrorCode: CosErrorCode;

  constructor(type: CosErrorType, cosErrorCode: CosErrorCode) {
    super(cosErrorCode.toString());
    this.type = type;
    this.cosErrorCode = cosErrorCode;
  }
}

export enum CosErrorType{
  Service = 'Service',
  Client = 'Client',
}