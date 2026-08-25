/**
 * CORS 跨域中间件
 * 处理 OPTIONS 预检请求并为所有响应添加跨域 header
 */

/**
 * CORS 中间件
 * @param {http.IncomingMessage} req
 * @param {http.ServerResponse} res
 * @returns {boolean} 如果是 OPTIONS 请求返回 true，表示已处理
 */
function corsMiddleware(req, res) {
  // 为所有响应添加 CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept, Origin');
  res.setHeader('Access-Control-Max-Age', '86400'); // 24 小时
  
  // 处理 OPTIONS 预检请求
  if (req.method === 'OPTIONS') {
    res.statusCode = 204;
    res.end();
    return true;
  }
  
  return false;
}

module.exports = { corsMiddleware };
