"""
DNF Admin Pro - Python 后端（SQLite 版本）
用于快速验证，无需 MySQL
"""

from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import sqlite3
import jwt
import datetime
import os
import bcrypt

app = Flask(__name__, static_folder='../frontend/dist', static_url_path='')
CORS(app)

SECRET_KEY = os.environ.get('JWT_SECRET', 'dnf-admin-secret-2026')
DB_PATH = os.environ.get('DB_PATH', '/root/.openclaw/workspace/dnf-admin/data/dnf-admin.db')

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    c = conn.cursor()
    
    # 管理员用户表
    c.execute('''CREATE TABLE IF NOT EXISTS admin_users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT DEFAULT 'viewer',
        status INTEGER DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )''')
    
    # 账号表
    c.execute('''CREATE TABLE IF NOT EXISTS accounts (
        uid INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT,
        status INTEGER DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )''')
    
    # 角色表
    c.execute('''CREATE TABLE IF NOT EXISTS charac_info (
        charac_no INTEGER PRIMARY KEY AUTOINCREMENT,
        account INTEGER NOT NULL,
        charac_name TEXT NOT NULL,
        charac_level INTEGER DEFAULT 1,
        charac_job INTEGER DEFAULT 0
    )''')
    
    # 用户物品表
    c.execute('''CREATE TABLE IF NOT EXISTS user_items (
        ui_id INTEGER PRIMARY KEY AUTOINCREMENT,
        charac_no INTEGER NOT NULL,
        it_id INTEGER NOT NULL,
        cnt INTEGER DEFAULT 1
    )''')
    
    # 邮件表
    c.execute('''CREATE TABLE IF NOT EXISTS user_mail (
        mail_id INTEGER PRIMARY KEY AUTOINCREMENT,
        charac_no INTEGER NOT NULL,
        title TEXT DEFAULT '',
        message TEXT,
        gold INTEGER DEFAULT 0,
        read_flag INTEGER DEFAULT 0,
        reg_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )''')
    
    # 点券表
    c.execute('''CREATE TABLE IF NOT EXISTS cash_cera (
        account INTEGER PRIMARY KEY,
        cera INTEGER DEFAULT 0,
        cera_point INTEGER DEFAULT 0
    )''')
    
    # 活动信息表
    c.execute('''CREATE TABLE IF NOT EXISTS dnf_event_info (
        event_id INTEGER PRIMARY KEY,
        event_name TEXT NOT NULL,
        event_explain TEXT,
        event_type INTEGER DEFAULT 0,
        status INTEGER DEFAULT 1
    )''')
    
    # 审计日志表
    c.execute('''CREATE TABLE IF NOT EXISTS audit_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT,
        action TEXT NOT NULL,
        target_type TEXT,
        target_id TEXT,
        details TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )''')
    
    # 插入默认管理员
    password_hash = bcrypt.hashpw('admin123'.encode(), bcrypt.gensalt()).decode()
    c.execute("INSERT OR IGNORE INTO admin_users (username, password, role) VALUES (?, ?, ?)",
              ('admin', password_hash, 'admin'))
    
    # 插入示例数据
    accounts = [
        ('testuser1', 'test1@example.com'),
        ('testuser2', 'test2@example.com'),
        ('testuser3', 'test3@example.com'),
    ]
    for username, email in accounts:
        c.execute("INSERT OR IGNORE INTO accounts (username, email) VALUES (?, ?)", (username, email))
    
    # 插入示例角色
    characters = [
        (1, '狂战士', 85, 1),
        (1, '鬼泣', 80, 2),
        (2, '散打', 75, 3),
        (3, '气功师', 70, 4),
    ]
    for account, name, level, job in characters:
        c.execute("INSERT OR IGNORE INTO charac_info (account, charac_name, charac_level, charac_job) VALUES (?, ?, ?, ?)",
                  (account, name, level, job))
    
    # 插入示例活动
    events = [
        (1, '双倍经验活动', '所有角色经验值翻倍', 1, 1),
        (2, '深渊爆率提升', '深渊地下城史诗装备爆率提升50%', 2, 1),
        (3, '签到送好礼', '每日签到领取奖励', 3, 0),
        (4, '充值返利', '充值点券返还双倍', 4, 0),
        (5, '周末狂欢', '周末限定活动', 5, 1),
    ]
    for event_id, name, explain, etype, status in events:
        c.execute("INSERT OR IGNORE INTO dnf_event_info (event_id, event_name, event_explain, event_type, status) VALUES (?, ?, ?, ?, ?)",
                  (event_id, name, explain, etype, status))
    
    conn.commit()
    conn.close()

def generate_token(username):
    payload = {
        'username': username,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
    }
    return jwt.encode(payload, SECRET_KEY, algorithm='HS256')

def verify_token(token):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        return payload['username']
    except:
        return None

def log_audit(username, action, target_type=None, target_id=None, details=None):
    conn = get_db()
    c = conn.cursor()
    c.execute("INSERT INTO audit_log (username, action, target_type, target_id, details) VALUES (?, ?, ?, ?, ?)",
              (username, action, target_type, target_id, details))
    conn.commit()
    conn.close()

# === 前端路由 ===
@app.route('/')
def index():
    return send_from_directory(app.static_folder, 'index.html')

@app.route('/<path:path>')
def static_files(path):
    return send_from_directory(app.static_folder, path)

# === API 路由 ===
@app.route('/api/v1/health')
def health():
    return jsonify({'status': 'ok', 'service': 'DNF Admin Pro'})

@app.route('/api/v1/auth/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    
    conn = get_db()
    c = conn.cursor()
    c.execute("SELECT * FROM admin_users WHERE username = ?", (username,))
    user = c.fetchone()
    conn.close()
    
    if user and bcrypt.checkpw(password.encode(), user['password'].encode()):
        token = generate_token(username)
        log_audit(username, 'login')
        return jsonify({
            'token': token,
            'user': {
                'id': user['id'],
                'username': user['username'],
                'role': user['role']
            }
        })
    
    return jsonify({'error': 'Invalid credentials'}), 401

@app.route('/api/v1/auth/me')
def get_me():
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    username = verify_token(token)
    if not username:
        return jsonify({'error': 'Unauthorized'}), 401
    
    conn = get_db()
    c = conn.cursor()
    c.execute("SELECT id, username, role FROM admin_users WHERE username = ?", (username,))
    user = c.fetchone()
    conn.close()
    
    if user:
        return jsonify(dict(user))
    return jsonify({'error': 'User not found'}), 404

# === 账号管理 ===
@app.route('/api/v1/accounts/search')
def search_accounts():
    q = request.args.get('q', '')
    conn = get_db()
    c = conn.cursor()
    if q:
        c.execute("SELECT * FROM accounts WHERE username LIKE ?", (f'%{q}%',))
    else:
        c.execute("SELECT * FROM accounts LIMIT 50")
    accounts = [dict(row) for row in c.fetchall()]
    conn.close()
    return jsonify(accounts)

@app.route('/api/v1/accounts/<int:uid>')
def get_account(uid):
    conn = get_db()
    c = conn.cursor()
    c.execute("SELECT * FROM accounts WHERE uid = ?", (uid,))
    account = c.fetchone()
    if not account:
        return jsonify({'error': 'Account not found'}), 404
    
    c.execute("SELECT * FROM charac_info WHERE account = ?", (uid,))
    characters = [dict(row) for row in c.fetchall()]
    conn.close()
    
    result = dict(account)
    result['characters'] = characters
    return jsonify(result)

# === 角色管理 ===
@app.route('/api/v1/characters/<int:cNo>')
def get_character(cNo):
    conn = get_db()
    c = conn.cursor()
    c.execute("SELECT * FROM charac_info WHERE charac_no = ?", (cNo,))
    charac = c.fetchone()
    if not charac:
        return jsonify({'error': 'Character not found'}), 404
    
    c.execute("SELECT * FROM user_items WHERE charac_no = ?", (cNo,))
    items = [dict(row) for row in c.fetchall()]
    conn.close()
    
    result = dict(charac)
    result['items'] = items
    return jsonify(result)

@app.route('/api/v1/characters/online')
def online_characters():
    return jsonify([
        {'charac_no': 1, 'charac_name': '狂战士', 'account': 1, 'level': 85},
        {'charac_no': 2, 'charac_name': '鬼泣', 'account': 1, 'level': 80},
    ])

# === GM 操作 ===
@app.route('/api/v1/gm/mail', methods=['POST'])
def send_mail():
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    username = verify_token(token)
    if not username:
        return jsonify({'error': 'Unauthorized'}), 401
    
    data = request.json
    conn = get_db()
    c = conn.cursor()
    
    c.execute("SELECT charac_no FROM charac_info WHERE charac_name = ?", (data.get('character_name'),))
    charac = c.fetchone()
    if not charac:
        return jsonify({'error': 'Character not found'}), 404
    
    c.execute("INSERT INTO user_mail (charac_no, title, message, gold) VALUES (?, ?, ?, ?)",
              (charac['charac_no'], data.get('title', ''), data.get('content', ''), data.get('gold', 0)))
    conn.commit()
    conn.close()
    
    log_audit(username, 'send_mail', 'character', str(charac['charac_no']), f"Title: {data.get('title')}")
    return jsonify({'success': True, 'message': 'Mail sent'})

@app.route('/api/v1/gm/item', methods=['POST'])
def send_item():
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    username = verify_token(token)
    if not username:
        return jsonify({'error': 'Unauthorized'}), 401
    
    data = request.json
    conn = get_db()
    c = conn.cursor()
    
    c.execute("SELECT charac_no FROM charac_info WHERE charac_name = ?", (data.get('character_name'),))
    charac = c.fetchone()
    if not charac:
        return jsonify({'error': 'Character not found'}), 404
    
    c.execute("INSERT INTO user_items (charac_no, it_id, cnt) VALUES (?, ?, ?)",
              (charac['charac_no'], data.get('item_id'), data.get('count', 1)))
    conn.commit()
    conn.close()
    
    log_audit(username, 'send_item', 'character', str(charac['charac_no']), f"Item ID: {data.get('item_id')}")
    return jsonify({'success': True, 'message': 'Item sent'})

@app.route('/api/v1/gm/gold', methods=['POST'])
def send_gold():
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    username = verify_token(token)
    if not username:
        return jsonify({'error': 'Unauthorized'}), 401
    
    data = request.json
    log_audit(username, 'send_gold', 'character', data.get('character_name'), f"Gold: {data.get('gold', 0)}")
    return jsonify({'success': True, 'message': 'Gold sent'})

@app.route('/api/v1/gm/cera', methods=['POST'])
def send_cera():
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    username = verify_token(token)
    if not username:
        return jsonify({'error': 'Unauthorized'}), 401
    
    data = request.json
    conn = get_db()
    c = conn.cursor()
    
    c.execute("SELECT uid FROM accounts WHERE username = ?", (data.get('username'),))
    account = c.fetchone()
    if not account:
        return jsonify({'error': 'Account not found'}), 404
    
    c.execute("INSERT OR REPLACE INTO cash_cera (account, cera, cera_point) VALUES (?, COALESCE((SELECT cera FROM cash_cera WHERE account = ?), 0) + ?, COALESCE((SELECT cera_point FROM cash_cera WHERE account = ?), 0) + ?)",
              (account['uid'], account['uid'], data.get('cera', 0), account['uid'], data.get('cera_point', 0)))
    conn.commit()
    conn.close()
    
    log_audit(username, 'send_cera', 'account', str(account['uid']), f"Cera: {data.get('cera', 0)}, Point: {data.get('cera_point', 0)}")
    return jsonify({'success': True, 'message': 'Cera sent'})

@app.route('/api/v1/gm/account/ban', methods=['POST'])
def ban_account():
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    username = verify_token(token)
    if not username:
        return jsonify({'error': 'Unauthorized'}), 401
    
    data = request.json
    conn = get_db()
    c = conn.cursor()
    
    c.execute("UPDATE accounts SET status = 2 WHERE uid = ?", (data.get('uid'),))
    conn.commit()
    conn.close()
    
    log_audit(username, 'ban_account', 'account', str(data.get('uid')), f"Reason: {data.get('reason', 'N/A')}")
    return jsonify({'success': True, 'message': 'Account banned'})

@app.route('/api/v1/gm/account/unban', methods=['POST'])
def unban_account():
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    username = verify_token(token)
    if not username:
        return jsonify({'error': 'Unauthorized'}), 401
    
    data = request.json
    conn = get_db()
    c = conn.cursor()
    
    c.execute("UPDATE accounts SET status = 1 WHERE uid = ?", (data.get('uid'),))
    conn.commit()
    conn.close()
    
    log_audit(username, 'unban_account', 'account', str(data.get('uid')))
    return jsonify({'success': True, 'message': 'Account unbanned'})

# === 活动管理 ===
@app.route('/api/v1/activities')
def list_activities():
    conn = get_db()
    c = conn.cursor()
    c.execute("SELECT * FROM dnf_event_info")
    activities = [dict(row) for row in c.fetchall()]
    conn.close()
    return jsonify(activities)

@app.route('/api/v1/activities/<int:event_id>/start', methods=['POST'])
def start_activity(event_id):
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    username = verify_token(token)
    if not username:
        return jsonify({'error': 'Unauthorized'}), 401
    
    conn = get_db()
    c = conn.cursor()
    c.execute("UPDATE dnf_event_info SET status = 1 WHERE event_id = ?", (event_id,))
    conn.commit()
    conn.close()
    
    log_audit(username, 'start_activity', 'activity', str(event_id))
    return jsonify({'success': True, 'message': 'Activity started'})

@app.route('/api/v1/activities/<int:event_id>/stop', methods=['POST'])
def stop_activity(event_id):
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    username = verify_token(token)
    if not username:
        return jsonify({'error': 'Unauthorized'}), 401
    
    conn = get_db()
    c = conn.cursor()
    c.execute("UPDATE dnf_event_info SET status = 0 WHERE event_id = ?", (event_id,))
    conn.commit()
    conn.close()
    
    log_audit(username, 'stop_activity', 'activity', str(event_id))
    return jsonify({'success': True, 'message': 'Activity stopped'})

# === 审计日志 ===
@app.route('/api/v1/audit/logs')
def audit_logs():
    conn = get_db()
    c = conn.cursor()
    c.execute("SELECT * FROM audit_log ORDER BY created_at DESC LIMIT 100")
    logs = [dict(row) for row in c.fetchall()]
    conn.close()
    return jsonify(logs)

if __name__ == '__main__':
    init_db()
    print("🚀 DNF Admin Pro 后端启动")
    print("📊 SQLite 数据库初始化完成")
    print("🌐 访问: http://127.0.0.1:8080")
    app.run(host='0.0.0.0', port=8080, debug=False)
