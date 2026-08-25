# COS Mock Server

用于 COS/CI SDK 网络代理测试的 Mock HTTP 服务器。

## 功能特性

- 模拟各种 HTTP 状态码响应 (2xx, 3xx, 4xx, 5xx)
- 模拟超时场景
- 模拟连接中断场景
- 模拟 CopyObject 207 错误响应
- 支持 CORS 跨域请求
- 请求/响应日志记录

## 安装

```bash
# 进入项目目录
cd mock-server

# 无需安装依赖，使用 Node.js 原生 http 模块
```

## 启动服务器

```bash
# 默认端口 8080
npm start

# 或指定端口
PORT=3000 npm start

# 或通过命令行参数指定端口
node src/server.js --port 3000
```

## API 接口

### 健康检查

```
GET /health
```

返回：`{"status": "ok"}`

### HTTP 状态码模拟

```
GET /{statusCode}
GET /{statusCode}r
```

- `/{statusCode}`: 返回指定状态码的响应
- `/{statusCode}r`: 返回指定状态码的响应，并添加 `x-cos-request-id` 和 `x-ci-request-id` header

支持的状态码：
- 2xx: 200, 204, 206
- 3xx: 301, 302, 307, 308
- 4xx: 400, 403, 404
- 5xx: 500, 503, 504

示例：
```bash
curl http://localhost:8080/200
curl http://localhost:8080/500r
```

### 超时模拟

```
GET /timeout
GET /timeoutr
```

延迟 10 秒后返回响应。`/timeoutr` 会添加 request-id header。

### 连接中断模拟

```
GET /shutdown
```

2 秒后主动关闭连接（模拟网络中断）。

### CopyObject 207 错误模拟

```
GET /InternalError_207
GET /SlowDown_207
GET /ServiceUnavailable_207
GET /null_207
```

返回 HTTP 207 状态码，body 为对应错误类型的 XML 响应：
- `InternalError_207`: 返回 InternalError 错误 XML
- `SlowDown_207`: 返回 SlowDown 错误 XML
- `ServiceUnavailable_207`: 返回 ServiceUnavailable 错误 XML
- `null_207`: 返回成功的 CopyObjectResult XML

## 配置

### 端口配置

端口配置优先级：命令行参数 > 环境变量 > 默认值 (8080)

```bash
# 环境变量
export PORT=3000

# 命令行参数
node src/server.js --port 3000
```

## 信号处理

服务器支持优雅关闭：
- `SIGINT` (Ctrl+C): 优雅关闭服务器
- `SIGTERM`: 优雅关闭服务器

## 目录结构

```
mock-server/
├── package.json
├── README.md
└── src/
    ├── server.js           # 服务器入口
    ├── middleware/
    │   ├── logger.js       # 请求日志中间件
    │   └── cors.js         # CORS 中间件
    └── routes/
        ├── health.js       # 健康检查路由
        ├── statusCode.js   # HTTP 状态码模拟路由
        ├── timeout.js      # 超时模拟路由
        ├── shutdown.js     # 连接中断模拟路由
        └── copyError.js    # CopyObject 207 错误模拟路由
```

## License

MIT
