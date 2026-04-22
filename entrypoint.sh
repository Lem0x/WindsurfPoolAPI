#!/bin/sh

# 1. 创建持久化数据和日志目录
mkdir -p /app/data
mkdir -p /app/logs

# 2. 定义需要持久化的文件列表
FILES="accounts.json stats.json runtime-config.json proxy-config.json model-access.json"

for file in $FILES; do
  # 如果持久化数据目录里没有这个文件，就初始化一个合法的空 JSON
  if [ ! -f "/app/data/$file" ]; then
    echo "{}" > "/app/data/$file"
  fi
  
  # 如果 /app 目录下残留了被 Docker 错误创建的同名文件夹，删掉它
  if [ -d "/app/$file" ] && [ ! -L "/app/$file" ]; then
    rm -rf "/app/$file"
  fi
  
  # 建立软链接：让程序以为文件还在 /app 根目录，实际上数据被写到了 /app/data 里
  ln -sf "/app/data/$file" "/app/$file"
done

# 3. 移交控制权，执行 Dockerfile 中原本的启动命令（如 node xxx）
exec "$@"
