#!/bin/bash

# 创建管道用于捕获并转发指令到服务端 stdin
PIPE=/tmp/terraria_pipe
[ -p "$PIPE" ] || mkfifo "$PIPE"

cleanup() {
    echo "[Entrypoint] Caught stop signal, sending 'exit' to Terraria Server..."
    echo "exit" > "$PIPE"
    wait "$SERVER_PID"
    echo "[Entrypoint] Terraria Server exited safely."
    exit 0
}

# 捕获容器停止信号
trap cleanup SIGTERM SIGINT

cd /vanilla

# 将管道作为 run.sh 的输入启动
tail -f "$PIPE" | ./run.sh "$@" &
SERVER_PID=$!

wait "$SERVER_PID"