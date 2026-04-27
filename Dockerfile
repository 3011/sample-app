# 示例应用 Dockerfile
# 这是一个简单的 nginx 应用，可以替换为你的实际应用

FROM nginx:alpine

# 复制应用文件（如果有）
# COPY ./dist /usr/share/nginx/html/

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

EXPOSE 80