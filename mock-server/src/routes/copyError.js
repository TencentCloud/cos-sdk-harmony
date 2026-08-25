/**
 * CopyObject 207 错误模拟路由
 * 模拟 CopyObject 操作返回 207 状态码的各种错误场景
 */

const { addRequestIdHeaders } = require('./statusCode');

/**
 * 生成错误 XML 响应体
 * @param {string} errorCode - 错误码
 * @param {string} errorMessage - 错误消息
 * @returns {string} XML 格式的错误响应
 */
function generateErrorXml(errorCode, errorMessage) {
  return `<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>${errorCode}</Code>
  <Message>${errorMessage}</Message>
  <Resource>/mock-resource</Resource>
  <RequestId>MOCK-REQUEST-ID</RequestId>
</Error>`;
}

/**
 * 生成成功的 CopyObjectResult XML 响应体
 * @returns {string} XML 格式的成功响应
 */
function generateSuccessXml() {
  const now = new Date().toISOString();
  return `<?xml version="1.0" encoding="UTF-8"?>
<CopyObjectResult>
  <LastModified>${now}</LastModified>
  <ETag>"mock-etag-12345"</ETag>
</CopyObjectResult>`;
}

// 支持的错误类型
const ERROR_TYPES = {
  'InternalError': {
    code: 'InternalError',
    message: 'We encountered an internal error. Please try again.'
  },
  'SlowDown': {
    code: 'SlowDown',
    message: 'Please reduce your request rate.'
  },
  'ServiceUnavailable': {
    code: 'ServiceUnavailable',
    message: 'Service is temporarily unavailable. Please retry.'
  }
};

/**
 * CopyObject 207 错误模拟路由处理器
 * 处理 /{errorType}_207 路径格式
 * @param {http.IncomingMessage} req
 * @param {http.ServerResponse} res
 * @returns {boolean} 如果路径匹配返回 true
 */
function copyErrorRoute(req, res) {
  const path = req.url.split('?')[0];
  
  // 匹配 /{errorType}_207 格式
  const match = path.match(/^\/(\w+)_207$/);
  if (!match) {
    return false;
  }
  
  const errorType = match[1];
  
  // 设置公共响应头
  res.statusCode = 207;
  res.setHeader('Content-Type', 'application/xml');
  addRequestIdHeaders(res);
  
  // 处理 null_207 - 返回成功响应
  if (errorType === 'null') {
    console.log('[CopyError Route] 返回成功的 CopyObjectResult');
    res.end(generateSuccessXml());
    return true;
  }
  
  // 处理错误类型
  const errorConfig = ERROR_TYPES[errorType];
  if (!errorConfig) {
    // 不支持的错误类型，返回 false 让其他路由处理
    return false;
  }
  
  console.log(`[CopyError Route] 返回 ${errorType} 错误`);
  res.end(generateErrorXml(errorConfig.code, errorConfig.message));
  return true;
}

module.exports = { copyErrorRoute };
