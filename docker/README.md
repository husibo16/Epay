# Docker 部署指南

该目录包含将 EPay 项目以生产可用的多容器架构运行所需的文件。拓扑如下：

- `php`：基于 `php:8.1-fpm-alpine`，预装常用扩展并加载项目代码。
- `nginx`：基于 `nginx:1.25-alpine`，提供静态资源及反向代理。
- `db`：官方 `mysql:8.0` 镜像，作为主数据库。

## 快速开始

1. **构建并启动服务**

   ```bash
   docker compose up -d --build
   ```

   默认情况下，Nginx 会监听宿主机 `8080` 端口，MySQL 对外暴露 `33060` 端口。

2. **首次安装**

   浏览器访问 `http://localhost:8080/install`，根据页面提示完成数据库初始化。

3. **调整环境变量**

   在生产环境部署时，建议通过 `.env` 文件（与 `docker-compose.yml` 同目录）覆盖下列变量：

   | 变量 | 默认值 | 说明 |
   | ---- | ------ | ---- |
   | `DB_HOST` | `db` | 数据库主机名（容器网络内） |
   | `DB_PORT` | `3306` | 数据库端口 |
   | `DB_USER` | `epay` | 数据库用户名 |
   | `DB_PASSWORD` | `supersecret` | 数据库密码 |
   | `DB_NAME` | `epay` | 数据库名称 |
   | `DB_PREFIX` | `pay` | 数据表前缀 |
   | `MYSQL_ROOT_PASSWORD` | `changeme` | MySQL root 密码 |
   | `TZ` | `Asia/Shanghai` | 容器时区 |

   运行 `docker compose up -d` 时，Compose 会自动读取 `.env` 文件。

4. **数据持久化**

   - `db-data` 卷持久化 MySQL 数据。
   - `php-sessions` 卷持久化 PHP Session 数据。

5. **日志**

   - Nginx 日志位于 Nginx 容器中的 `/var/log/nginx/`。
   - PHP-FPM 日志可通过 `docker compose logs php` 查看。

## 生产环境建议

- 为 MySQL 选择专用的存储卷，并定期备份 `db-data`。
- 使用反向代理（例如 Traefik 或外层 Nginx）终止 TLS，将 80 端口暴露给负载均衡器。
- 如需水平扩展 PHP 容器，可在 Compose 文件中增加副本数，同时启用共享的 Session 存储（例如 Redis）。
- 将默认密码替换为强随机密码，并将 `.env` 文件限制在安全位置。

## 常见问题排查

- **构建时提示 `failed to calculate checksum ... "/default.conf": not found`**：
  旧版本的 Dockerfile 会尝试从镜像根目录复制 `default.conf` 和 `php.ini`，在 Compose 的构建上下文为项目根目录时会找不到文件。请确保拉取最新代码，或在自定义 Dockerfile 中使用 `COPY ./docker/nginx/default.conf` 与 `COPY ./docker/php/php.ini` 这样的绝对相对路径。
