# 放弃 Alpine，改用基于 Debian 的 slim 镜像以提供 glibc 支持
FROM node:20-slim

# 安装 wget (用于健康检查) 并创建 app 用户 (Debian 的用户创建命令与 Alpine 不同)
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/* \
    && groupadd -r app && useradd -r -g app app

WORKDIR /app

# 复制源代码并赋予权限
COPY --chown=app:app package.json ./
COPY --chown=app:app src ./src
COPY --chown=app:app docs ./docs

# 环境变量设置
ENV LS_BINARY_PATH=/opt/windsurf/language_server_linux_x64
ENV PORT=3003
ENV LS_PORT=42100
ENV LOG_LEVEL=info

# 创建运行时所需的目录并赋予 app 用户权限
RUN mkdir -p /app/logs /tmp/windsurf-workspace \
    && chown -R app:app /app /tmp/windsurf-workspace

# 复制启动脚本并修复换行符/权限
COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

# 强制使用 root 启动，确保能顺利读写外部挂载的 ./data 和 ./logs
USER root

EXPOSE 3003

# 设置自定义入口点
ENTRYPOINT ["/entrypoint.sh"]

# 健康检查
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3003/health || exit 1

CMD ["node", "src/index.js"]
