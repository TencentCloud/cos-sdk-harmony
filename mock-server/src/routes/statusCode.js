/**
 * HTTP 状态码模拟路由
 * 支持模拟各种 HTTP 状态码响应
 */

// 支持的状态码及其描述
const STATUS_CODES = {
  // 2xx 成功
  200: 'OK',
  204: 'No Content',
  206: 'Partial Content',
  // 3xx 重定向
  301: 'Moved Permanently',
  302: 'Found',
  307: 'Temporary Redirect',
  308: 'Permanent Redirect',
  // 4xx 客户端错误
  400: 'Bad Request',
  403: 'Forbidden',
  404: 'Not Found',
  // 5xx 服务器错误
  500: 'Internal Server Error',
  503: 'Service Unavailable',
  504: 'Gateway Timeout'
};

/**
 * 生成唯一的 request-id
 * @returns {string}
 */
function generateRequestId() {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substring(2, 10);
  return `MOCK${timestamp}${random}`.toUpperCase();
}

/**
 * 添加 request-id headers
 * @param {http.ServerResponse} res
 */
function addRequestIdHeaders(res) {
  const requestId = generateRequestId();
  res.setHeader('x-cos-request-id', requestId);
  res.setHeader('x-ci-request-id', requestId);
}

/**
 * HTTP 状态码模拟路由处理器
 * 支持路径格式：/{statusCode} 和 /{statusCode}r
 * @param {http.IncomingMessage} req
 * @param {http.ServerResponse} res
 * @returns {boolean} 如果路径匹配返回 true
 */
function statusCodeRoute(req, res) {
  // 解析路径，去除查询参数
  const path = req.url.split('?')[0];
  
  // 匹配 /{statusCode} 或 /{statusCode}r 格式
  const match = path.match(/^\/(\d{3})(r)?$/);
  if (!match) {
    return false;
  }
  
  const statusCode = parseInt(match[1], 10);
  const withRequestId = match[2] === 'r';
  
  // 检查是否为支持的状态码
  if (!STATUS_CODES[statusCode]) {
    return false;
  }
  
  // 设置状态码
  res.statusCode = statusCode;
  res.setHeader('Content-Type', 'application/json');
  
  // 如果路径以 'r' 结尾，添加 request-id headers
  if (withRequestId) {
    addRequestIdHeaders(res);
  }
  
  // 处理特殊状态码
  if (statusCode === 204) {
    // 204 No Content 不应该有响应体
    res.end();
  } else if (statusCode >= 300 && statusCode < 400) {
    // 3xx 重定向，添加 Location header
    res.setHeader('Location', '/redirected');
    res.end(JSON.stringify({
      statusCode: statusCode,
      message: STATUS_CODES[statusCode],
      location: '/redirected'
    }));
  } else {
    // 其他状态码
    res.end(JSON.stringify({
      statusCode: statusCode,
      message: STATUS_CODES[statusCode]
    }));
  }
  
  return true;
}

module.exports = { statusCodeRoute, generateRequestId, addRequestIdHeaders };
