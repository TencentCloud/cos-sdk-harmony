/**
 * 请求日志中间件
 * 记录请求和响应的详细信息
 */

/**
 * 获取当前时间戳
 * @returns {string}
 */
function getTimestamp() {
  return new Date().toISOString();
}

/**
 * 格式化 headers 对象
 * @param {Object} headers
 * @returns {string}
 */
function formatHeaders(headers) {
  const entries = Object.entries(headers);
  if (entries.length === 0) {
    return '{}';
  }
  return JSON.stringify(headers, null, 2);
}

/**
 * 日志中间件
 * 记录请求方法、路径、header 信息，以及响应状态码和 header 信息
 * @param {http.IncomingMessage} req
 * @param {http.ServerResponse} res
 */
function loggerMiddleware(req, res) {
  const startTime = Date.now();
  const timestamp = getTimestamp();
  
  // 记录请求信息
  console.log('\n' + '='.repeat(60));
  console.log(`[${timestamp}] 收到请求`);
  console.log(`  方法: ${req.method}`);
  console.log(`  路径: ${req.url}`);
  console.log(`  请求头:`);
  Object.entries(req.headers).forEach(([key, value]) => {
    console.log(`    ${key}: ${value}`);
  });
  
  // 保存原始的 end 方法
  const originalEnd = res.end.bind(res);
  
  // 重写 end 方法以记录响应信息
  res.end = function(...args) {
    const duration = Date.now() - startTime;
    const responseTimestamp = getTimestamp();
    
    console.log(`[${responseTimestamp}] 发送响应`);
    console.log(`  状态码: ${res.statusCode}`);
    console.log(`  耗时: ${duration}ms`);
    console.log(`  响应头:`);
    const responseHeaders = res.getHeaders();
    Object.entries(responseHeaders).forEach(([key, value]) => {
      console.log(`    ${key}: ${value}`);
    });
    console.log('='.repeat(60));
    
    // 调用原始的 end 方法
    return originalEnd(...args);
  };
}

module.exports = { loggerMiddleware };
