<?php
/*数据库配置
 * 生产环境建议通过环境变量提供数据库连接信息。
 * 支持以下环境变量：
 *   DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME, DB_PREFIX
 */
$dbconfig=array(
        'host' => getenv('DB_HOST') ?: 'localhost', //数据库服务器
        'port' => getenv('DB_PORT') ?: 3306, //数据库端口
        'user' => getenv('DB_USER') ?: '', //数据库用户名
        'pwd' => getenv('DB_PASSWORD') ?: '', //数据库密码
        'dbname' => getenv('DB_NAME') ?: '', //数据库名
        'dbqz' => getenv('DB_PREFIX') ?: 'pay' //数据表前缀
);