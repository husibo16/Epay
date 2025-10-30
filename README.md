## 版本与镜像选择

- **PHP**：使用 `php:7.4-fpm-alpine`，与项目中使用的 PDO、GD、bcMath 等扩展保持兼容，同时保证与现有代码中的 MySQL 驱动、会话及模板逻辑保持一致。镜像内预编译 `bcmath`、`gd`（含 FreeType/JPEG 支持）、`gmp`、`intl`、`pdo_mysql`、`redis` 等扩展以满足支付与国密相关依赖。
- **Nginx**：选用 `nginx:1.25-alpine`，轻量化且易于扩展 HTTPS、缓存控制等配置。
- **MySQL**：使用 `mysql:5.7`，兼容老版本 SQL 语法与 `mysql_native_password` 认证方式，避免与旧版客户端的兼容性问题。
- **Redis**：使用 `redis:7-alpine`，提供缓存与会话支持，可视情况通过密码或 TLS 加固安全。

如需升级到更高版本的 PHP/MySQL，请先在测试环境中验证项目兼容性。

## 服务拓扑

| 服务        | 镜像/构建              | 说明                                                         |
|-------------|------------------------|--------------------------------------------------------------|
| `php`       | 本地构建 (`epay-php`)   | PHP-FPM 应用容器，运行 Epay 主站点，负责 PHP 业务逻辑。       |
| `nginx`     | `nginx:1.25-alpine`    | 反向代理 + 静态资源，转发请求至 `php` 服务。                |
| `mysql`     | `mysql:5.7`            | 主数据库，挂载数据卷保证持久化。                             |
| `redis`     | `redis:7-alpine`       | 缓存/会话，采用 AOF 持久化。                                 |
| `scheduler` | 本地构建 (`epay-php`)   | 使用 supercronic 定时执行 `cron.php`，处理异步/计划任务。     |

所有服务连接到 `backend` 网络，`nginx` 额外暴露在 `public` 网络并映射宿主机端口。

## 快速开始

1. 复制环境变量模板：

   ```bash
   cp env.example .env
   ```

2. 按需修改 `.env` 中的数据库口令、端口等信息，并同步更新 `config.php` 中的数据库配置（或使用挂载/自定义配置文件）。

3. 构建并启动：

   ```bash
   docker compose up -d --build
   ```

   镜像构建阶段已经安装 Composer 依赖，并在运行时通过共享的 `app-code` 数据卷提供给 PHP 与 Nginx，无需在宿主机额外执行 `composer install`。

4. 首次运行完成后访问 `http://localhost:8080` 进行安装或验证，生产环境建议配置 HTTPS 及反向代理证书。

## 数据持久化

- `mysql-data`：MySQL 数据目录，确保数据库内容不会随容器删除而丢失。
- `redis-data`：Redis AOF 持久化目录，记录写操作日志。
- `app-code`：镜像内的应用代码与依赖，由 PHP 与 Nginx 共享，确保安装阶段生成的依赖不会被宿主机挂载覆盖。
- `php-log`、`nginx-log`：分别挂载 PHP 与 Nginx 日志目录，便于集中收集。

建议将这些卷映射到宿主机受控路径，并使用备份策略（如定期 `mysqldump`、AOF 备份）。

## 网络与端口

- 默认暴露 `8080` 端口，避免与宿主机已有 80 端口冲突，可在 `.env` 或 `docker-compose.yml` 中自定义。
- 所有内部服务通过 `backend` 网络通讯，未直接暴露在公共网络，减少攻击面。
- 如需对外提供 MySQL/Redis 访问，请使用专用跳板或限制访问来源 IP，并启用密码/TLS。

## 生产安全建议

- **权限控制**：容器以非特权用户 `www-data` 运行 PHP-FPM，`entrypoint.sh` 会在启动时调整目录权限。
- **环境变量管理**：生产环境请使用 Docker Secret 或外部密钥管理系统（如 HashiCorp Vault）存储敏感配置，避免直接写入 `.env`。
- **资源限制**：通过 Docker Compose 的 `deploy.resources.limits`（Swarm/Kubernetes）或在运行时使用 `--cpus`、`--memory` 进行资源配额，防止单个服务占用过多资源。
- **镜像瘦身**：基础镜像采用 Alpine，安装必要扩展后移除构建依赖，保持镜像精简。
- **自动化更新**：结合 CI/CD（如 GitHub Actions）实现镜像构建、漏洞扫描和部署流程的自动化。

## 健康检查与监控

- `php`、`mysql`、`redis`、`nginx` 均配置了健康检查命令，其中 `nginx` 通过 `/healthz` 静态探针避免触发应用 404，Docker 将在服务异常时自动重启容器。
- 建议接入 Prometheus + Grafana、ELK/EFK Stack 或云厂商监控方案，实现 CPU、内存、QPS、慢查询等指标的可视化监控。
- 结合 Filebeat/Fluent Bit 收集 `php-log`、`nginx-log`，集中到日志平台进行检索与告警。

## 备份与恢复

- 定期执行数据库备份：
  ```bash
  docker compose exec mysql mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > backup.sql
  ```
- Redis AOF 文件可配合 `redis-check-aof` 做一致性校验。
- 建议将备份文件同步至对象存储或离线介质，并配置恢复演练流程。

## 自定义与扩展

- 如需开启 HTTPS，可在 `nginx.conf` 中新增 443 监听并挂载证书文件。
- 若需要横向扩展，可将 `php` 服务的 `replicas` 调整为多实例，并在上游负载均衡器（或 Kubernetes Ingress）中进行轮询。
- Scheduler 可根据实际业务修改 `scheduler.cron`，例如添加多条定时任务或调整执行频率。

## 故障排查

- 查看容器日志：`docker compose logs -f <service>`。
- 进入容器调试：`docker compose exec php sh`。
- 检查健康状态：`docker compose ps`。

> ⚠️ 在生产环境部署前请于预发布环境完成充分测试，并根据实际业务规模调整资源与安全策略。
