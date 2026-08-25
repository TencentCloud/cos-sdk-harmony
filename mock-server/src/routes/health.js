/**
 * 健康检查路由
 * 用于检测服务器是否正常运行
 */

/**
 * 健康检查路由处理器
 * @param {http.IncomingMessage} req
 * @param {http.ServerResponse} res
 * @returns {boolean} 如果路径匹配返回 true
 */
function healthRoute(req, res) {
  if (req.url === '/health' || req.url === '/health/') {
    res.statusCode = 200;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ status: 'ok' }));
    return true;
  }
  return false;
}

module.exports = { healthRoute };
