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

# 复制容器 stdin（PTY）到 fd 3，避免后台任务 stdin 被替换导致 attach 输入丢失
exec 3<&0 2>/dev/null || true

# 将容器控制台输入（docker/podman attach）转发到管道
cat <&3 > "$PIPE" &

# 将管道作为 run.sh 的输入启动。
# 过滤 attach/SSH 建立时产生的首个空行（真实输入前不存在合法空行，
# 之后创建世界时的空种子回车等空行不受影响）
seen_input=false
while IFS= read -r line; do
    if [ -n "$line" ]; then
        seen_input=true
    elif ! $seen_input; then
        continue
    fi
    printf '%s\n' "$line"
done < "$PIPE" | ./run.sh "$@" &
SERVER_PID=$!

wait "$SERVER_PID"