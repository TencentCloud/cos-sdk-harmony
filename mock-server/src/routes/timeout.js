/**
 * 超时场景模拟路由
 * 模拟网络超时场景，延迟响应
 */

const { addRequestIdHeaders } = require('./statusCode');

// 超时延迟时间（毫秒）
const TIMEOUT_DELAY = 1500; // 1.5 秒

/**
 * 超时模拟路由处理器
 * 处理 /timeout 和 /timeoutr 路径
 * @param {http.IncomingMessage} req
 * @param {http.ServerResponse} res
 * @returns {boolean} 如果路径匹配返回 true
 */
function timeoutRoute(req, res) {
  const path = req.url.split('?')[0];
  
  // 匹配 /timeout 或 /timeoutr
  if (path !== '/timeout' && path !== '/timeoutr') {
    return false;
  }
  
  const withRequestId = path === '/timeoutr';
  
  console.log(`[Timeout Route] 开始延迟 ${TIMEOUT_DELAY}ms...`);
  
  // 延迟响应
  setTimeout(() => {
    // 检查连接是否仍然有效
    if (res.writableEnded) {
      console.log('[Timeout Route] 连接已关闭，跳过响应');
      return;
    }
    
    res.statusCode = 200;
    res.setHeader('Content-Type', 'application/json');
    
    if (withRequestId) {
      addRequestIdHeaders(res);
    }
    
    res.end(JSON.stringify({
      message: 'Timeout simulation completed',
      delay: TIMEOUT_DELAY
    }));
    
    console.log(`[Timeout Route] 延迟完成，已发送响应`);
  }, TIMEOUT_DELAY);
  
  return true;
}

module.exports = { timeoutRoute };
