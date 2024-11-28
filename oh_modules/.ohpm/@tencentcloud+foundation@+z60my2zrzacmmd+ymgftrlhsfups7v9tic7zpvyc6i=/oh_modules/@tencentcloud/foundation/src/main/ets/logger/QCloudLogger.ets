import hilog from '@ohos.hilog'
import { LoggerOptions } from './LoggerOptions'

export class QCloudLogger {
  private static mTag?: string = "QCloudLog"
  private static mDomain?: number = 0x0369 //日志对应的领域标识，范围是0x0~0xFFFF
  private static mHilog?: boolean = true //默认是用hilog进行打印
  private static mShowLogLocation?: boolean = false //展示点击的位置
  private static mLogSize = 1024 //打印的最大长度，默认是1024
  private static mClose?: boolean = true

  static setClose(close: boolean) {
    QCloudLogger.mClose = close
  }

  /*
   * 初始化tag、domain等属性
   * */
  static init(options: LoggerOptions) {
    const tag: string | undefined = options.tag //日志输出Tag
    const domain: number | undefined = options.domain //日志对应的领域标识，范围是0x0~0xFFFF
    const close: boolean | undefined = options.close //是否关闭日志
    const isHilog: boolean | undefined = options.isHilog //是否是hilog打印
    const showLogLocation: boolean | undefined = options.showLogLocation //是否展示日志位置
    const logSize: number | undefined = options.logSize //日志输出大小
    if (tag != undefined) {
      QCloudLogger.mTag = tag
    }
    if (domain != undefined) {
      QCloudLogger.mDomain = domain
    }
    if (close != undefined) {
      QCloudLogger.mClose = close
    }
    if (isHilog != undefined) {
      QCloudLogger.mHilog = isHilog
    }
    if (showLogLocation != undefined) {
      QCloudLogger.mShowLogLocation = showLogLocation
    }
    if (logSize != undefined) {
      QCloudLogger.mLogSize = logSize
    }

  }

  //需要先调用isLoggable确认某个domain、tag和日志级别是否被禁止打印日志
  static isLoggable(level: hilog.LogLevel): boolean {
    return hilog.isLoggable(QCloudLogger.mDomain, QCloudLogger.mTag, level)
  }

  /*
* debug日志
* */
  static debug(message: string | object, tag?: string) {
    QCloudLogger.logLevel(hilog.LogLevel.DEBUG, tag, message)
  }

  /*
* info日志
* */
  static info(message: string | object, tag?: string) {
    QCloudLogger.logLevel(hilog.LogLevel.INFO, tag, message)
  }

  /*
* error日志,不带标签
* */
  static error(message: string | object, tag?: string) {
    QCloudLogger.logLevel(hilog.LogLevel.ERROR, tag, message)
  }


  /*
* warn日志
* */
  static warn(message: string | object, tag?: string) {
    QCloudLogger.logLevel(hilog.LogLevel.WARN, tag, message)
  }

  /*
* fatal日志
* */
  static fatal(message: string, tag?: string) {
    QCloudLogger.logLevel(hilog.LogLevel.FATAL, tag, message)
  }

  /*
* console形式打印log日志,只支持console
* */
  static log(message: string | object, tag?: string | undefined) {
    QCloudLogger.logLevel(hilog.LogLevel.INFO, tag, message)
  }

  /*
   *统一输出日志
   * */
  private static logLevel(level: hilog.LogLevel, tag?: string, message: string | object = "") {
    //如果关闭状态，则不打印日志
    if (QCloudLogger.mClose) {
      return
    }

    //未传递时
    if (tag == undefined) {
      tag = QCloudLogger.mTag
    }

    const content = QCloudLogger.getMessage(level, tag, message) //最终的内容展示

    const len = content.length / QCloudLogger.mLogSize
    for (let i = 0; i < len; i++) {
      let con = content.substring(i * QCloudLogger.mLogSize, (i + 1) * QCloudLogger.mLogSize)
      if (i != 0) {
        con = "|" + con
      }
      //打印日志
      if (QCloudLogger.mHilog) {
        //使用hilog
        switch (level) {
          case hilog.LogLevel.INFO: //info
            hilog.info(QCloudLogger.mDomain, tag, con)
            break
          case hilog.LogLevel.WARN: //WARN
            hilog.warn(QCloudLogger.mDomain, tag, con)
            break
          case hilog.LogLevel.DEBUG: //DEBUG
            hilog.debug(QCloudLogger.mDomain, tag, con)
            break
          case hilog.LogLevel.ERROR: //ERROR
            hilog.error(QCloudLogger.mDomain, tag, con)
            break
          case hilog.LogLevel.FATAL: //FATAL
            hilog.fatal(QCloudLogger.mDomain, tag, con)
            break
        }
      } else {
        //使用console
        switch (level) {
          case hilog.LogLevel.INFO: //info
            console.info(con)
            break
          case hilog.LogLevel.WARN: //WARN
            console.warn(con)
            break
          case hilog.LogLevel.DEBUG: //DEBUG
            console.debug(con)
            break
          case hilog.LogLevel.ERROR: //ERROR
            console.error(con)
            break
          case hilog.LogLevel.FATAL: //FATAL
            console.log(con)
            break
        }
      }

    }

  }

  /**
   * 获取输出位置
   * */
  static getMessage(level: hilog.LogLevel, tag: string = "", message: string | object): string {
    let log = "┌───────" + tag + "────────────────────────────────────────────────────────────────────────────────"
    log = log.substring(0, log.length - tag.length) + "\n"

    try {
      if (QCloudLogger.mShowLogLocation && level == hilog.LogLevel.ERROR) {
        //展示位置
        const stackTrace = new Error().stack
        const traceArray = stackTrace!.split('\n')
        const trace = traceArray[traceArray.length-2]
        log = log + "|" + trace
      }

      let type = typeof message
      if (type == "object") {
        //是对象
        message = QCloudLogger.getObjectToJson(message)
      } else if (type == "string") {
        //判断是否包含大括号
        const content = message + ""
        if (content.startsWith("{") && content.endsWith("}")) {
          //对象
          const obj: object = JSON.parse(message.toString())
          message = QCloudLogger.getObjectToJson(obj)
        } else {
          message = content
        }
      }
      log = log + "\n|    " + message
    } catch (e) {

    }
    log = log + "\n└───────────────────────────────────────────────────────────────────────────────────────"
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