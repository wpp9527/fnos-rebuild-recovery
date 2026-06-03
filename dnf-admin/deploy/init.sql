-- DNF Admin Pro 数据库初始化
-- 创建数据库和用户

CREATE DATABASE IF NOT EXISTS dnf_service;
CREATE DATABASE IF NOT EXISTS d_taiwan;
CREATE DATABASE IF NOT EXISTS taiwan_cain;
CREATE DATABASE IF NOT EXISTS taiwan_cain_2nd;
CREATE DATABASE IF NOT EXISTS taiwan_billing;
CREATE DATABASE IF NOT EXISTS taiwan_login;
CREATE DATABASE IF NOT EXISTS taiwan_game_event;

-- 创建用户并授权
CREATE USER IF NOT EXISTS 'dnf_admin'@'%' IDENTIFIED BY 'dnf_admin_2026';
GRANT SELECT, INSERT, UPDATE, DELETE ON dnf_service.* TO 'dnf_admin'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON d_taiwan.* TO 'dnf_admin'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON taiwan_cain.* TO 'dnf_admin'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON taiwan_cain_2nd.* TO 'dnf_admin'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON taiwan_billing.* TO 'dnf_admin'@'%';
GRANT SELECT ON taiwan_login.* TO 'dnf_admin'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON taiwan_game_event.* TO 'dnf_admin'@'%';
FLUSH PRIVILEGES;

-- 账号表
CREATE TABLE IF NOT EXISTS accounts (
    uid INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    status TINYINT DEFAULT 1 COMMENT '1=正常 2=封禁 3=冻结',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 角色表
CREATE TABLE IF NOT EXISTS charac_info (
    charac_no INT AUTO_INCREMENT PRIMARY KEY,
    account INT NOT NULL,
    charac_name VARCHAR(50) NOT NULL,
    charac_level INT DEFAULT 1,
    charac_job INT DEFAULT 0,
    charac_pos INT DEFAULT 0,
    inven_weight INT DEFAULT 0,
    cur_map INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_account (account),
    INDEX idx_charac_name (charac_name),
    INDEX idx_level (charac_level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 用户物品表
CREATE TABLE IF NOT EXISTS user_items (
    ui_id INT AUTO_INCREMENT PRIMARY KEY,
    charac_no INT NOT NULL,
    it_id INT NOT NULL,
    it_var1 INT DEFAULT 0,
    it_var2 INT DEFAULT 0,
    it_var3 INT DEFAULT 0,
    it_var4 INT DEFAULT 0,
    it_var5 INT DEFAULT 0,
    it_var6 INT DEFAULT 0,
    it_var7 INT DEFAULT 0,
    it_var8 INT DEFAULT 0,
    it_var9 INT DEFAULT 0,
    it_var10 INT DEFAULT 0,
    cnt INT DEFAULT 1,
    slot INT DEFAULT 0,
    expire_date TIMESTAMP NULL,
    obtain_from TINYINT DEFAULT 0,
    reg_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    stat TINYINT DEFAULT 0,
    INDEX idx_charac_no (charac_no),
    INDEX idx_it_id (it_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 邮件表
CREATE TABLE IF NOT EXISTS user_mail (
    mail_id INT AUTO_INCREMENT PRIMARY KEY,
    charac_no INT NOT NULL,
    sender VARCHAR(50) DEFAULT 'System',
    title VARCHAR(100) DEFAULT '',
    message TEXT,
    it_id1 INT DEFAULT 0,
    it_id2 INT DEFAULT 0,
    it_id3 INT DEFAULT 0,
    it_id4 INT DEFAULT 0,
    it_id5 INT DEFAULT 0,
    it_cnt1 INT DEFAULT 0,
    it_cnt2 INT DEFAULT 0,
    it_cnt3 INT DEFAULT 0,
    it_cnt4 INT DEFAULT 0,
    it_cnt5 INT DEFAULT 0,
    gold BIGINT DEFAULT 0,
    cera INT DEFAULT 0,
    cera_point INT DEFAULT 0,
    read_flag TINYINT DEFAULT 0,
    receive_flag TINYINT DEFAULT 0,
    reg_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expire_date TIMESTAMP NULL,
    INDEX idx_charac_no (charac_no),
    INDEX idx_read_flag (read_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 点券表
CREATE TABLE IF NOT EXISTS cash_cera (
    account INT PRIMARY KEY,
    cera INT DEFAULT 0,
    cera_point INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 活动信息表
CREATE TABLE IF NOT EXISTS dnf_event_info (
    event_id INT PRIMARY KEY,
    event_name VARCHAR(100) NOT NULL,
    event_explain TEXT,
    event_type INT DEFAULT 0,
    status TINYINT DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 活动日志表
CREATE TABLE IF NOT EXISTS dnf_event_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    event_type INT NOT NULL,
    parameter1 INT DEFAULT 0,
    parameter2 INT DEFAULT 0,
    server_id INT DEFAULT 0,
    event_flag INT DEFAULT 0,
    start_time TIMESTAMP NULL,
    end_time TIMESTAMP NULL,
    occ_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_event_type (event_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 封号信息表
CREATE TABLE IF NOT EXISTS member_punish_info (
    id INT AUTO_INCREMENT PRIMARY KEY,
    m_id INT NOT NULL,
    punish_type TINYINT DEFAULT 1,
    occ_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    punish_value INT DEFAULT 101,
    apply_flag TINYINT DEFAULT 0,
    start_time TIMESTAMP NULL,
    end_time TIMESTAMP NULL,
    reason TEXT,
    INDEX idx_m_id (m_id),
    INDEX idx_apply_flag (apply_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 审计日志表
CREATE TABLE IF NOT EXISTS audit_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    username VARCHAR(50),
    action VARCHAR(50) NOT NULL,
    target_type VARCHAR(50),
    target_id VARCHAR(100),
    details JSON,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 管理员用户表
CREATE TABLE IF NOT EXISTS admin_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'viewer' COMMENT 'admin/editor/viewer',
    status TINYINT DEFAULT 1,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 插入默认管理员 (密码: admin123)
INSERT INTO admin_users (username, password, role) VALUES 
('admin', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'admin')
ON DUPLICATE KEY UPDATE username=username;

-- 插入示例活动数据
INSERT INTO dnf_event_info (event_id, event_name, event_explain, event_type) VALUES
(1, '双倍经验活动', '所有角色经验值翻倍', 1),
(2, '深渊爆率提升', '深渊地下城史诗装备爆率提升50%', 2),
(3, '签到送好礼', '每日签到领取奖励', 3),
(4, '充值返利', '充值点券返还双倍', 4),
(5, '周末狂欢', '周末限定活动', 5)
ON DUPLICATE KEY UPDATE event_name=event_name;
