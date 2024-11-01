import hilog from '@ohos.hilog'

export class Logger {
  private static mTag?: string = "TransferLog"
  private static mDomain?: number = 0x0666 //日志对应的领域标识，范围是0x0~0xFFFF
  private static mShowLogLocation?: boolean = true //展示点击的位置
  private static mLogSize = 1024 //打印的最大长度，默认是1024

  /*
* debug日志
* */
  static debug(message: string | object, tag?: string) {
    Logger.logLevel(hilog.LogLevel.DEBUG, tag, message)
  }

  /*
* info日志
* */
  static info(message: string | object, tag?: string) {
    Logger.logLevel(hilog.LogLevel.INFO, tag, message)
  }

  /*
* error日志,不带标签
* */
  static error(message: string | object, tag?: string) {
    Logger.logLevel(hilog.LogLevel.ERROR, tag, message)
  }


  /*
* warn日志
* */
  static warn(message: string | object, tag?: string) {
    Logger.logLevel(hilog.LogLevel.WARN, tag, message)
  }

  /*
* fatal日志
* */
  static fatal(message: string, tag?: string) {
    Logger.logLevel(hilog.LogLevel.FATAL, tag, message)
  }

  /*
   *统一输出日志
   * */
  private static logLevel(level: hilog.LogLevel, tag?: string, message: string | object = "") {
    //未传递时
    if (tag == undefined) {
      tag = Logger.mTag
    }

    const content = Logger.getMessage(level, tag, message) //最终的内容展示

    const len = content.length / Logger.mLogSize
    for (let i = 0; i < len; i++) {
      let con = content.substring(i * Logger.mLogSize, (i + 1) * Logger.mLogSize)
      if (i != 0) {
        con = "|" + con
      }
      //打印日志
      //使用hilog
      switch (level) {
        case hilog.LogLevel.INFO: //info
          hilog.info(Logger.mDomain, tag, con)
          break
        case hilog.LogLevel.WARN: //WARN
          hilog.warn(Logger.mDomain, tag, con)
          break
        case hilog.LogLevel.DEBUG: //DEBUG
          hilog.debug(Logger.mDomain, tag, con)
          break
        case hilog.LogLevel.ERROR: //ERROR
          hilog.error(Logger.mDomain, tag, con)
          break
        case hilog.LogLevel.FATAL: //FATAL
          hilog.fatal(Logger.mDomain, tag, con)
          break
      }
    }

  }

  /**
   * 获取输出位置
   * */
  static getMessage(level: hilog.LogLevel, tag: string = "", message: string | object): string {
    let log = "┌~~~~~~~" + tag + "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    log = log.substring(0, log.length - tag.length) + "\n"

    try {
      if (Logger.mShowLogLocation && level == hilog.LogLevel.ERROR) {
        //展示位置
        const stackTrace = new Error().stack
        const traceArray = stackTrace!.split('\n')
        const trace = traceArray[traceArray.length-2]
        log = log + "|" + trace
      }

      let type = typeof message
      if (type == "object") {
        //是对象
        message = Logger.getObjectToJson(message)
      } else if (type == "string") {
        //判断是否包含大括号
        const content = message + ""
        if (content.startsWith("{") && content.endsWith("}")) {
          //对象
          const obj: object = JSON.parse(message.toString())
          message = Logger.getObjectToJson(obj)
        } else {
          message = content
        }
      }
      log = log + "\n|    " + message
    } catch (e) {

    }
    log = log + "\n└~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    return log
  }

  /*
   *对象转Json
   * */
  private static getObjectToJson(message: string | object): string {
    const json = JSON.stringify(message, null, 2)
    const endMessage = json.replace(/\n/g, "\n|    ")
    return endMessage
  }
}