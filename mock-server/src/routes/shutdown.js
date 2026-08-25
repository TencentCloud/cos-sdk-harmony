/**
 * 连接中断模拟路由
 * 模拟网络中断场景，主动关闭连接
 */

// 关闭连接前的延迟时间（毫秒）
const SHUTDOWN_DELAY = 800; // 0.8 秒

/**
 * 连接中断模拟路由处理器
 * 处理 /shutdown 路径
 * @param {http.IncomingMessage} req
 * @param {http.ServerResponse} res
 * @returns {boolean} 如果路径匹配返回 true
 */
function shutdownRoute(req, res) {
  const path = req.url.split('?')[0];
  
  // 匹配 /shutdown
  if (path !== '/shutdown') {
    return false;
  }
  
  console.log(`[Shutdown Route] 将在 ${SHUTDOWN_DELAY}ms 后关闭连接...`);
  
  // 延迟后主动关闭连接
  setTimeout(() => {
    // 获取底层 socket 并销毁
    const socket = res.socket;
    if (socket && !socket.destroyed) {
      console.log('[Shutdown Route] 主动销毁 socket 连接');
      socket.destroy();
    } else {
      console.log('[Shutdown Route] Socket 已被销毁或不存在');
    }
  }, SHUTDOWN_DELAY);
  
  return true;
}

module.exports = { shutdownRoute };
