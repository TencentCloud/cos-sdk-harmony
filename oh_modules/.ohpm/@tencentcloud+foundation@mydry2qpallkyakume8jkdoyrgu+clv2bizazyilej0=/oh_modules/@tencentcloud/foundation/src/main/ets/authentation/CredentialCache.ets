import { QCloudCredential } from './QCloudCredential';

export class CredentialCache {

  credential:QCloudCredential | null = null;

  private static instance: CredentialCache | undefined;
  public static singleCache(): CredentialCache {
    if (!CredentialCache.instance) {
      CredentialCache.instance = new CredentialCache();
    }
    return CredentialCache.instance;
  }

  clearCredential(){
    CredentialCache.singleCache().credential = null;
  }

  cacheCredential(credential:QCloudCredential){
    CredentialCache.singleCache().credential = credential;
  }

  getCredential():QCloudCredential|null{
    if (CredentialCache.singleCache().credential?.valid()) {
      return CredentialCache.singleCache().credential;
    }
    return null;
  }
}