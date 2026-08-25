/**
 * COS Mock Server - 服务器入口
 * 用于 COS/CI SDK 网络代理测试的 Mock HTTP 服务器
 */

const http = require('http');

// 导入中间件
const { loggerMiddleware } = require('./middleware/logger');
const { corsMiddleware } = require('./middleware/cors');

// 导入路由处理器
const { healthRoute } = require('./routes/health');
const { statusCodeRoute } = require('./routes/statusCode');
const { timeoutRoute } = require('./routes/timeout');
const { shutdownRoute } = require('./routes/shutdown');
const { copyErrorRoute } = require('./routes/copyError');

/**
 * 解析命令行参数获取端口
 * @returns {number|null}
 */
function getPortFromArgs() {
  const args = process.argv.slice(2);
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--port' && args[i + 1]) {
      const port = parseInt(args[i + 1], 10);
      if (!isNaN(port)) {
        return port;
      }
    }
  }
  return null;
}

/**
 * 获取服务器端口
 * 优先级：命令行参数 > 环境变量 > 默认值 8080
 * @returns {number}
 */
function getPort() {
  const argPort = getPortFromArgs();
  if (argPort) {
    return argPort;
  }
  
  const envPort = parseInt(process.env.PORT, 10);
  if (!isNaN(envPort)) {
    return envPort;
  }
  
  return 8080;
}

/**
 * 路由分发器
 * @param {http.IncomingMessage} req
 * @param {http.ServerResponse} res
 */
function routeHandler(req, res) {
  const url = req.url;
  
  // 健康检查路由
  if (healthRoute(req, res)) {
    return;
  }
  
  // 超时模拟路由
  if (timeoutRoute(req, res)) {
    return;
  }
  
  // 连接中断模拟路由
  if (shutdownRoute(req, res)) {
    return;
  }
  
  // CopyObject 207 错误模拟路由
  if (copyErrorRoute(req, res)) {
    return;
  }
  
  // HTTP 状态码模拟路由
  if (statusCodeRoute(req, res)) {
    return;
  }
  
  // 404 默认处理
  res.statusCode = 404;
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify({ error: 'Not Found', path: url }));
}

/**
 * 请求处理器 - 组合中间件和路由
 * @param {http.IncomingMessage} req
 * @param {http.ServerResponse} res
 */
function requestHandler(req, res) {
  // 应用日志中间件
  loggerMiddleware(req, res);
  
  // 应用 CORS 中间件
  if (corsMiddleware(req, res)) {
    // OPTIONS 请求已处理
    return;
  }
  
  // 路由处理
  routeHandler(req, res);
}

// 创建 HTTP 服务器
const server = http.createServer(requestHandler);

// 获取端口
const PORT = getPort();

// 启动服务器
server.listen(PORT, () => {
  console.log(`[Mock Server] 服务器启动成功，监听端口: ${PORT}`);
  console.log(`[Mock Server] 健康检查: http://localhost:${PORT}/health`);
});

// 端口占用错误处理
server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`[Mock Server] 错误: 端口 ${PORT} 已被占用`);
    process.exit(1);
  } else {
    console.error(`[Mock Server] 服务器错误:`, err);
    process.exit(1);
  }
});

// 优雅关闭处理
function gracefulShutdown(signal) {
  console.log(`\n[Mock Server] 收到 ${signal} 信号，正在关闭服务器...`);
  server.close(() => {
    console.log('[Mock Server] 服务器已关闭');
    process.exit(0);
  });
  
  // 强制关闭超时（5秒）
  setTimeout(() => {
    console.error('[Mock Server] 强制关闭服务器');
    process.exit(1);
  }, 5000);
}

// 监听关闭信号
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));

module.exports = { server };
