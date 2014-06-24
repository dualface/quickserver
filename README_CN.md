# 基本架构


- 客户端使用 WebSockets 连接服务端（OpenResty）。
- 对于每一个客户端连接，服务端框架（Server Framework）用一个线程（ngx.thread，实际上是协程）监听客户端发送的消息。


## 请求/响应模型

1. 收到客户端消息后，解码消息（JSON 格式），取出 msgid（键名 \_id\_） 和 action 参数。然后将消息转发给相应的 Action 方法处理。
2. Action 方法如果成功运行，返回两个值：true 和结果。
	- 如果客户端消息包含 msgid：
		- 如果结果为 nil，框架创建 table {"\_id\_":msgid}，并编码为 JSON 发送到客户端
		- 如果结果为 tabel，框架在 table 中添加 "\_id\_" = msgid，并编码为 JSON 发送到客户端
		- 否则记录错误信息：ERR\_SERVER\_INVALID\_RESULT。创建 table {"\_id\_":msgid,"err":"ERR\_SERVER\_INVALID\_RESULT"}，并编码为 JSON 发送到客户端
	- 没有 msgid 时检查执行结果。如果结果不为 nil，则记录错误信息：ERR\_SERVER\_INVALID\_RESULT
3.  Action 方法如果运行出错，返回两个值：false 和错误信息。
  - 如果客户端消息包含 msgid：记录错误信息。创建 table {"\_id\_":msgid,"err":错误信息}，并编码为 JSON 发送到客户端
  - 没有 msgid 时记录错误信息

~
