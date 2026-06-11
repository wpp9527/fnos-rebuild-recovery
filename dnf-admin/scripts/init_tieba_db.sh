#!/bin/bash

# 初始化百度贴吧数据库表
# 需要在 MySQL 服务器上执行

SERVER="192.168.1.204"
DB_USER="root"
DB_PASS="88888888"
DB_NAME="dnf_tieba"

echo "初始化贴吧数据库..."

# 创建数据库
sshpass -p wp930803 ssh -o StrictHostKeyChecking=no root@$SERVER "mysql -u$DB_USER -p$DB_PASS -e 'CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'"

# 创建表
sshpass -p wp930803 ssh -o StrictHostKeyChecking=no root@$SERVER "mysql -u$DB_USER -p$DB_PASS $DB_NAME -e '
CREATE TABLE IF NOT EXISTS tieba_posts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    tieba_name VARCHAR(100) NOT NULL,
    title VARCHAR(500) NOT NULL,
    content TEXT,
    author VARCHAR(100),
    author_level INT DEFAULT 0,
    reply_count INT DEFAULT 0,
    view_count INT DEFAULT 0,
    post_time DATETIME,
    last_reply DATETIME,
    url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FULLTEXT INDEX idx_title_content (title, content),
    INDEX idx_tieba_name (tieba_name),
    INDEX idx_post_time (post_time),
    INDEX idx_author (author)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
'"

echo "✅ 数据库初始化完成"
