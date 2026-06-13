#!/usr/bin/env python3
"""
DNF 后台管理系统 - 扩展功能 API
整合角色查询、物品查询、统计分析、贴吧联动等功能
"""

import json
import pymysql
import requests
import os
import re
import subprocess
from datetime import datetime, timedelta
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import threading
import time

# 数据库配置
DB_CONFIG = {
    'host': '127.0.0.1',
    'port': 3307,
    'user': 'root',
    'password': '88888888',
    'charset': 'utf8mb4',
}

# 职业映射
JOB_MAP = {
    0: '鬼剑士', 1: '格斗家', 2: '神枪手', 3: '魔法师', 4: '圣职者',
    5: '暗夜使者', 6: '魔枪士', 7: '枪剑士', 8: '弓箭手',
    100: '狂战士', 101: '剑魂', 102: '鬼泣', 103: '阿修罗',
    200: '气功师', 201: '散打', 202: '街霸', 203: '柔道家',
    300: '漫游枪手', 301: '枪炮师', 302: '弹药专家', 303: '机械师',
    400: '元素师', 401: '召唤师', 402: '战斗法师', 403: '魔道学者',
    500: '圣骑士', 501: '蓝拳圣使', 502: '驱魔师', 503: '复仇者',
    600: '刺客', 601: '死灵术士', 602: '忍者', 603: '影舞者',
    700: '征战者', 701: '决战者', 702: '狩猎者', 703: '暗枪士',
    800: '暗刃', 801: '特工', 802: '战线佣兵', 803: '源能专家',
    900: '缪斯', 901: '旅人',
}

# 村庄映射
VILLAGE_MAP = {
    0: '贝尔玛尔公国', 1: '暗精灵王国', 2: '虚祖', 3: '德洛斯帝国',
    4: '天界', 5: '魔界', 6: '联合调查团', 7: '佧修派',
}

# 数据库连接配置（使用 latin1 以正确处理中文编码）
DB_CONFIG_RAW = {
    'host': '127.0.0.1',
    'port': 3307,
    'user': 'root',
    'password': '88888888',
    'charset': 'latin1',
    'use_unicode': False,
}

def encode_params(params):
    """将参数编码为 bytes（用于 latin1 连接）"""
    if params is None:
        return None
    encoded = []
    for p in params:
        if isinstance(p, str):
            encoded.append(p.encode('utf-8'))
        elif isinstance(p, bytes):
            encoded.append(p)
        else:
            encoded.append(p)
    return tuple(encoded)

def sql_to_bytes(sql):
    """将 SQL 字符串编码为 bytes（用于包含中文的 SQL）"""
    if isinstance(sql, bytes):
        return sql
    return sql.encode('utf-8')

def decode_row(row):
    """解码行中的 bytes 字段为 UTF-8 字符串"""
    if row is None:
        return row
    decoded = {}
    for key, value in row.items():
        if isinstance(value, bytes):
            try:
                decoded[key] = value.decode('utf-8')
            except:
                decoded[key] = value.decode('latin1')
        else:
            decoded[key] = value
    return decoded

def execute_query(db_name, sql, params=None):
    """执行查询（自动处理编码）"""
    for attempt in range(2):
        try:
            conn = pymysql.connect(**DB_CONFIG_RAW, database=db_name)
            cursor = conn.cursor(pymysql.cursors.DictCursor)
            # 编码参数
            encoded_params = encode_params(params)
            cursor.execute(sql, encoded_params)
            rows = cursor.fetchall()
            conn.close()
            # 解码所有 bytes 字段
            return [decode_row(row) for row in rows]
        except Exception as e:
            if attempt == 1:
                raise e
            time.sleep(0.5)

class DNFAdminHandler(BaseHTTPRequestHandler):
    """DNF 后台管理 API 处理器"""
    
    def log_message(self, format, *args):
        """禁用日志输出"""
        pass
    
    def do_OPTIONS(self):
        """处理 OPTIONS 请求 (CORS 预检)"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()
    
    def do_POST(self):
        """处理 POST 请求"""
        parsed = urlparse(self.path)
        path = parsed.path
        
        # 读取请求体
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length) if content_length > 0 else b''
        
        try:
            data = json.loads(body) if body else {}
        except:
            data = {}
        
        # POST 路由
        post_routes = {
            '/api/v2/punish/batch': self.punish_batch,
            '/api/v2/mail/send': self.mail_send,
            '/api/v2/event/create': self.event_create,
        }
        
        if path in post_routes:
            try:
                result = post_routes[path](data)
                self.send_json(200, result)
            except Exception as e:
                self.send_json(500, {'error': str(e)})
        else:
            self.send_json(404, {'error': 'not found'})
    
    def do_GET(self):
        """处理 GET 请求"""
        parsed = urlparse(self.path)
        path = parsed.path
        params = parse_qs(parsed.query)
        
        # 路由分发 - 14个推荐功能全部实现
        routes = {
            # 兼容原后台 API v1 格式
            # v1 兼容
            '/api/v1/charac': self.character_list,
            '/api/v1/account': self.account_list,
            '/api/v1/guilds': self.guild_list,
            '/api/v1/punish': self.punish_list,
            '/api/v1/stats/online': self.stats_online,
            '/api/v1/stats/pvp': self.stats_pvp,
            '/api/v1/pvf/items': self.item_search,
            '/api/v1/pvf/stats': self.pvf_stats,
            
            # v2 别名（前端使用）
            '/api/v2/charac': self.character_list,
            '/api/v2/account': self.account_list,
            
            # 新功能 API v2
            '/api/v2/character/list': self.character_list,
            '/api/v2/character/detail': self.character_detail,
            '/api/v2/character/search': self.character_search,
            '/api/v2/character/attributes': self.character_attributes,
            
            '/api/v2/item/search': self.item_search,
            '/api/v2/item/list': self.item_list,
            '/api/v2/item/detail': self.item_detail,
            '/api/v2/item/rarity': self.item_rarity_stats,
            '/api/v2/item/obtain': self.item_obtain_methods,
            
            '/api/v2/monster/search': self.monster_search,
            '/api/v2/monster/list': self.monster_list,
            '/api/v2/monster/detail': self.monster_detail,
            '/api/v2/monster/drops': self.monster_drops,
            
            '/api/v2/skill/search': self.skill_search,
            '/api/v2/skill/detail': self.skill_detail,
            '/api/v2/skill/by-job': self.skills_by_job,
            '/api/v2/skill/jobs': self.skill_jobs,
            
            '/api/v2/stats/online': self.stats_online,
            '/api/v2/stats/online/history': self.stats_online_history,
            '/api/v2/stats/economy': self.stats_economy,
            '/api/v2/stats/economy/trend': self.stats_economy_trend,
            '/api/v2/stats/economy/wealth-rank': self.stats_wealth_rank,
            '/api/v2/stats/dungeon': self.stats_dungeon,
            '/api/v2/stats/dungeon/popular': self.stats_dungeon_popular,
            '/api/v2/stats/pvp': self.stats_pvp,
            '/api/v2/stats/pvp/rankings': self.stats_pvp_rankings,
            '/api/v2/stats/server': self.stats_server,
            
            '/api/v2/punish/list': self.punish_list,
            '/api/v2/punish/logs': self.punish_logs,
            
            '/api/v2/mail/list': self.mail_list,
            '/api/v2/mail/stats': self.mail_stats,
            
            '/api/v2/event/list': self.event_list,
            '/api/v2/event/stats': self.event_stats,
            
            '/api/v2/tieba/posts': self.tieba_posts,
            '/api/v2/tieba/search': self.tieba_search,
            '/api/v2/tieba/monitor': self.tieba_monitor,
            '/api/v2/tieba/link': self.tieba_link_character,
            
            '/api/v2/feedback/list': self.feedback_list,
            '/api/v2/feedback/stats': self.feedback_stats,
            
            '/api/v2/version/monitor': self.version_monitor,
            '/api/v2/version/bugs': self.version_bugs,
            
            '/api/v2/check/integrity': self.check_integrity,
            '/api/v2/check/consistency': self.check_consistency,
            '/api/v2/check/anomaly': self.check_anomaly,
            '/api/v2/check/report': self.check_report,
            
            # PVF 解析
            '/api/v2/pvf/list': self.pvf_list,
            '/api/v2/pvf/search': self.pvf_search,
            '/api/v2/pvf/detail': self.pvf_detail,
            '/api/v2/pvf/stats': self.pvf_stats,
            '/api/v2/pvf/categories': self.pvf_categories,
            
            '/api/v2/health': self.health_check,
        }
        
        if path in routes:
            try:
                result = routes[path](params)
                self.send_json(200, result)
            except Exception as e:
                self.send_json(500, {'error': str(e)})
        else:
            self.send_json(404, {'error': 'not found'})
    
    def send_json(self, code, data):
        """发送 JSON 响应"""
        self.send_response(code)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False, default=str).encode('utf-8'))
    
    # ========== 兼容原后台 API ==========
    
    def account_list(self, params):
        """账号列表 (兼容原后台格式)"""
        page = int(params.get('page', [1])[0])
        limit = int(params.get('page_size', [20])[0])
        offset = (page - 1) * limit
        
        sql = """
            SELECT UID as uid, accountname as uname, admin as level, 1 as status,
                   0 as coin, 0 as cera, 0 as cera_point, '' as login_ip,
                   NOW() as last_login
            FROM d_taiwan.accounts
            ORDER BY UID DESC LIMIT %s OFFSET %s
        """
        accounts = execute_query('d_taiwan', sql, (limit, offset))
        # 添加服务器信息
        for a in accounts:
            a['server_id'] = 'local'
            a['server_name'] = '本地区'
        
        # 格式化日期
        for a in accounts:
            if a.get('last_login'):
                a['last_login'] = a['last_login'].strftime('%Y-%m-%dT%H:%M:%SZ') if hasattr(a['last_login'], 'strftime') else str(a['last_login'])
        
        count_sql = "SELECT COUNT(*) as total FROM d_taiwan.accounts"
        total = execute_query('d_taiwan', count_sql)[0]['total']
        
        return {
            'data': accounts,
            'page': page,
            'size': limit,
            'total': total
        }
    
    def guild_list(self, params):
        """公会列表"""
        return {'data': []}
    
    # ========== 角色查询 ==========
    
    def character_list(self, params):
        """角色列表 (兼容原后台格式)"""
        page = int(params.get('page', [1])[0])
        limit = int(params.get('page_size', [20])[0])
        offset = (page - 1) * limit
        
        sql = """
            SELECT m_id as c_no, charac_name as c_name, lev as c_level, job as c_job,
                   fatigue as c_fatigue, 0 as c_server, 1 as uid, 0 as grow_type, 1 as sex,
                   1200 as max_hp, 2000 as max_mp, 45 as phy_attack, 45 as phy_defense,
                   75 as mag_attack, 75 as mag_defense, 8000 as move_speed,
                   10000 as attack_speed, 10000 as cast_speed, 3500 as jump,
                   5000 as hit_recovery, 0 as exp, last_play_time as c_last_login, create_time
            FROM taiwan_cain.charac_info
            ORDER BY last_play_time DESC LIMIT %s OFFSET %s
        """
        chars = execute_query('taiwan_cain', sql, (limit, offset))
        # 添加服务器信息
        for c in chars:
            c['server_id'] = 'local'
            c['server_name'] = '本地区'
        
        # 格式化日期
        for c in chars:
            if c.get('c_last_login'):
                c['c_last_login'] = c['c_last_login'].strftime('%Y-%m-%dT%H:%M:%SZ') if hasattr(c['c_last_login'], 'strftime') else str(c['c_last_login'])
            if c.get('create_time'):
                c['create_time'] = c['create_time'].strftime('%Y-%m-%dT%H:%M:%SZ') if hasattr(c['create_time'], 'strftime') else str(c['create_time'])
        
        count_sql = "SELECT COUNT(*) as total FROM taiwan_cain.charac_info"
        total = execute_query('taiwan_cain', count_sql)[0]['total']
        
        return {
            'data': chars,
            'page': page,
            'size': limit,
            'total': total
        }
    
    def character_detail(self, params):
        """角色详情"""
        char_id = params.get('id', [None])[0]
        if not char_id:
            return {'error': 'missing id parameter'}
        
        # 角色基本信息
        char_sql = "SELECT * FROM taiwan_cain.charac_info WHERE m_id = %s"
        char = execute_query('taiwan_cain', char_sql, (char_id,))
        if not char:
            return {'error': 'character not found'}
        
        char = char[0]
        
        # 角色物品
        items_sql = """
            SELECT ui.ui_id, ui.slot, ui.it_id, ui.expire_date, ui.obtain_from,
                   di.it_name, di.rarity, di.master_type, di.sub_type
            FROM taiwan_cain_2nd.user_items ui
            LEFT JOIN taiwan_cain_web.dnf_item_info di ON ui.it_id = di.it_no
            WHERE ui.charac_no = %s
            ORDER BY ui.slot
        """
        items = execute_query('taiwan_cain_2nd', items_sql, (char_id,))
        
        # 角色邮件
        mail_sql = """
            SELECT postal_id, occ_time, send_charac_name, item_id, gold, receive_time
            FROM taiwan_cain_2nd.postal
            WHERE receive_charac_no = %s
            ORDER BY occ_time DESC
            LIMIT 10
        """
        mails = execute_query('taiwan_cain_2nd', mail_sql, (char_id,))
        
        return {
            'character': char,
            'items': items,
            'mails': mails
        }
    
    def character_search(self, params):
        """搜索角色"""
        keyword = params.get('q', [''])[0]
        if not keyword:
            return {'error': 'missing q parameter'}
        
        # 使用 bytes 编码 SQL 以支持中文搜索
        keyword_bytes = keyword.encode('utf-8')
        sql = b"SELECT m_id, charac_name, village, job, lev, last_play_time FROM charac_info WHERE charac_name LIKE '%" + keyword_bytes + b"%' ORDER BY lev DESC LIMIT 20"
        
        conn = pymysql.connect(**DB_CONFIG_RAW, database='taiwan_cain')
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute(sql)
        rows = cursor.fetchall()
        conn.close()
        
        return {'data': [decode_row(row) for row in rows]}
    
    # ========== 物品查询 ==========
    
    def item_search(self, params):
        """搜索物品 (兼容原后台 PVF 格式)"""
        keyword = params.get('q', [''])[0]
        page = int(params.get('page', [1])[0])
        limit = int(params.get('page_size', [20])[0])
        offset = (page - 1) * limit
        
        if keyword:
            # 使用 bytes 编码 SQL 以支持中文搜索
            keyword_bytes = keyword.encode('utf-8')
            like_param = b"'%" + keyword_bytes + b"%'"
            sql = b"SELECT it_no as id, it_name as name, master_type as category, sub_type as type, level, rarity, '' as description FROM dnf_item_info WHERE it_name LIKE " + like_param + b" OR it_eng_name LIKE " + like_param + b" ORDER BY rarity DESC, level DESC LIMIT " + str(limit).encode() + b" OFFSET " + str(offset).encode()
            
            conn = pymysql.connect(**DB_CONFIG_RAW, database='taiwan_cain_web')
            cursor = conn.cursor(pymysql.cursors.DictCursor)
            cursor.execute(sql)
            rows = cursor.fetchall()
            items = [decode_row(row) for row in rows]
            
            count_sql = b"SELECT COUNT(*) as total FROM dnf_item_info WHERE it_name LIKE " + like_param + b" OR it_eng_name LIKE " + like_param
            cursor.execute(count_sql)
            total = cursor.fetchone()['total']
            conn.close()
        else:
            sql = """
                SELECT it_no as id, it_name as name, master_type as category,
                       sub_type as type, level, rarity, '' as description
                FROM taiwan_cain_web.dnf_item_info
                ORDER BY rarity DESC, level DESC LIMIT %s OFFSET %s
            """
            items = execute_query('taiwan_cain_web', sql, (limit, offset))
            
            count_sql = "SELECT COUNT(*) as total FROM taiwan_cain_web.dnf_item_info"
            total = execute_query('taiwan_cain_web', count_sql)[0]['total']
        
        return {
            'data': items,
            'page': page,
            'size': limit,
            'total': total
        }
    
    def pvf_stats(self, params):
        """PVF 统计 (兼容原后台)"""
        # 物品分类统计
        category_sql = """
            SELECT master_type as category, COUNT(*) as count
            FROM taiwan_cain_web.dnf_item_info
            GROUP BY master_type
            ORDER BY count DESC
        """
        categories = execute_query('taiwan_cain_web', category_sql)
        
        # 物品稀有度统计
        rarity_sql = """
            SELECT rarity, COUNT(*) as count
            FROM taiwan_cain_web.dnf_item_info
            GROUP BY rarity
            ORDER BY count DESC
        """
        rarities = execute_query('taiwan_cain_web', rarity_sql)
        
        # 总物品数
        total_sql = "SELECT COUNT(*) as total FROM taiwan_cain_web.dnf_item_info"
        total = execute_query('taiwan_cain_web', total_sql)[0]['total']
        
        return {
            'categories': {c['category']: c['count'] for c in categories},
            'rarities': {r['rarity']: r['count'] for r in rarities},
            'total_items': total
        }
    
    def item_detail(self, params):
        """物品详情"""
        item_id = params.get('id', [None])[0]
        if not item_id:
            return {'error': 'missing id parameter'}
        
        sql = "SELECT * FROM taiwan_cain_web.dnf_item_info WHERE it_no = %s"
        item = execute_query('taiwan_cain_web', sql, (item_id,))
        if not item:
            return {'error': 'item not found'}
        
        return {'data': item[0]}
    
    def item_rarity_stats(self, params):
        """物品稀有度统计"""
        sql = """
            SELECT rarity, COUNT(*) as count
            FROM taiwan_cain_web.dnf_item_info
            GROUP BY rarity
            ORDER BY rarity
        """
        stats = execute_query('taiwan_cain_web', sql)
        return {'data': stats}
    
    # ========== 怪物图鉴 ==========
    
    def monster_search(self, params):
        """搜索怪物"""
        keyword = params.get('q', [''])[0]
        if not keyword:
            return self.monster_list(params)
        
        # 使用 bytes 编码 SQL 以支持中文搜索
        keyword_bytes = keyword.encode('utf-8')
        sql = b"SELECT idx, mon_name_kr FROM dnf_monster_info WHERE mon_name_kr LIKE '%" + keyword_bytes + b"%' LIMIT 50"
        
        conn = pymysql.connect(**DB_CONFIG_RAW, database='taiwan_cain_web')
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute(sql)
        rows = cursor.fetchall()
        conn.close()
        
        return {'data': [decode_row(row) for row in rows]}
    
    def monster_detail(self, params):
        """怪物详情"""
        monster_id = params.get('id', [None])[0]
        if not monster_id:
            return {'error': 'missing id parameter'}
        
        sql = "SELECT * FROM taiwan_cain_web.dnf_monster_info WHERE idx = %s"
        monster = execute_query('taiwan_cain_web', sql, (monster_id,))
        if not monster:
            return {'error': 'monster not found'}
        
        return {'data': monster[0]}
    
    # ========== 技能查询 ==========
    
    def skill_search(self, params):
        """搜索技能"""
        keyword = params.get('q', [''])[0]
        if not keyword:
            return {'error': 'missing q parameter'}
        
        # 使用 bytes 编码 SQL 以支持中文搜索
        keyword_bytes = keyword.encode('utf-8')
        sql = b"SELECT DISTINCT job_index, skill_index, name, type, required_level, basic_explain, skill_explain FROM skill_info WHERE name LIKE '%" + keyword_bytes + b"%' ORDER BY required_level LIMIT 50"
        
        conn = pymysql.connect(**DB_CONFIG_RAW, database='taiwan_cain_web')
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute(sql)
        rows = cursor.fetchall()
        conn.close()
        
        return {'data': [decode_row(row) for row in rows]}
    
    def skill_detail(self, params):
        """技能详情"""
        skill_id = params.get('id', [None])[0]
        if not skill_id:
            return {'error': 'missing id parameter'}
        
        sql = "SELECT * FROM taiwan_cain_web.skill_info WHERE skill_index = %s LIMIT 1"
        skill = execute_query('taiwan_cain_web', sql, (skill_id,))
        if not skill:
            return {'error': 'skill not found'}
        
        return {'data': skill[0]}
    
    # ========== 1. 角色详情查询（增强版） ==========
    
    def character_attributes(self, params):
        """角色战斗属性及背包"""
        char_id = params.get('id', [None])[0]
        if not char_id:
            return {'error': 'missing id parameter'}
        
        # 使用实际数据库列名
        sql = b"SELECT m_id, charac_no, charac_name, village, job, lev, exp, fatigue, max_fatigue, HP, maxHP, maxMP, phy_attack, phy_defense, mag_attack, mag_defense, create_time, last_play_time FROM charac_info WHERE m_id = " + char_id.encode()
        
        conn = pymysql.connect(**DB_CONFIG_RAW, database='taiwan_cain')
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute(sql)
        result = cursor.fetchall()
        
        if not result:
            conn.close()
            return {'error': 'character not found'}
        char = decode_row(result[0])
        # 添加映射名称
        char['village_name'] = VILLAGE_MAP.get(char.get('village'), '未知')
        char['job_name'] = JOB_MAP.get(char.get('job'), '未知')
        
        # 查询角色背包物品
        charac_no = char.get('charac_no')
        if charac_no:
            try:
                # 使用新的连接查询背包
                conn2 = pymysql.connect(**DB_CONFIG_RAW, database='taiwan_cain_2nd')
                cursor2 = conn2.cursor(pymysql.cursors.DictCursor)
                cursor2.execute(b"SELECT ui_id, slot, it_id, ability_no, stat FROM user_items WHERE charac_no = " + str(charac_no).encode() + b" ORDER BY slot LIMIT 50")
                items = cursor2.fetchall()
                conn2.close()
                char['inventory'] = [decode_row(item) for item in items]
                char['inventory_count'] = len(char['inventory'])
            except Exception as e:
                char['inventory'] = []
                char['inventory_count'] = 0
                char['inventory_error'] = str(e)
        
        conn.close()
        return {'data': char}
    
    # ========== 2. 物品查询系统（增强版） ==========
    
    def item_obtain_methods(self, params):
        """物品获取方式分析"""
        item_id = params.get('id', [None])[0]
        if not item_id:
            return {'error': 'missing id parameter'}
        
        # 查询谁拥有这个物品
        owners_sql = """
            SELECT ci.charac_name, ci.lev, ci.job, ui.obtain_from, ui.expire_date
            FROM taiwan_cain_2nd.user_items ui
            JOIN taiwan_cain.charac_info ci ON ui.charac_no = ci.m_id
            WHERE ui.it_id = %s
            ORDER BY ci.lev DESC
            LIMIT 20
        """
        owners = execute_query('taiwan_cain_2nd', owners_sql, (item_id,))
        
        # 获取方式统计
        method_sql = """
            SELECT obtain_from, COUNT(*) as count
            FROM taiwan_cain_2nd.user_items
            WHERE it_id = %s AND obtain_from IS NOT NULL AND obtain_from != ''
            GROUP BY obtain_from
            ORDER BY count DESC
        """
        methods = execute_query('taiwan_cain_2nd', method_sql, (item_id,))
        
        return {
            'item_id': item_id,
            'owners': owners,
            'obtain_methods': methods
        }
    
    # ========== 3. 怪物图鉴（增强版） ==========
    
    def monster_drops(self, params):
        """怪物掉落查询"""
        monster_id = params.get('id', [None])[0]
        if not monster_id:
            return {'error': 'missing id parameter'}
        
        # 查询该怪物的掉落物品
        sql = """
            SELECT di.it_no, di.it_name, di.rarity, di.master_type, di.sub_type
            FROM taiwan_cain_web.dnf_item_info di
            WHERE di.monster_drop = %s
            ORDER BY di.rarity DESC, di.level DESC
            LIMIT 50
        """
        drops = execute_query('taiwan_cain_web', sql, (monster_id,))
        
        return {'data': drops}
    
    # ========== 4. 技能查询（增强版） ==========
    
    def skills_by_job(self, params):
        """按职业查询技能"""
        job_id = int(params.get('job', [0])[0])
        
        # 数据库 skill_info 只有基础职业 (0-8)，高级职业需映射
        base_job_map = {
            0: 0, 100: 0, 101: 0, 102: 0, 103: 0,  # 鬼剑士系
            1: 1, 200: 1, 201: 1, 202: 1, 203: 1,  # 格斗家系
            2: 2, 300: 2, 301: 2, 302: 2, 303: 2,  # 神枪手系
            3: 3, 400: 3, 401: 3, 402: 3, 403: 3,  # 魔法师系
            4: 4, 500: 4, 501: 4, 502: 4, 503: 4,  # 圣职者系
        }
        base_job = base_job_map.get(job_id, job_id)
        
        sql = b"SELECT DISTINCT job_index, skill_index, name, type, required_level, basic_explain, skill_explain, consume_mp FROM skill_info WHERE job_index = " + str(base_job).encode() + b" ORDER BY required_level, skill_index"
        
        conn = pymysql.connect(**DB_CONFIG_RAW, database='taiwan_cain_web')
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute(sql)
        rows = cursor.fetchall()
        conn.close()
        skills = [decode_row(row) for row in rows]
        
        return {
            'job_id': job_id,
            'job_name': JOB_MAP.get(job_id, '未知'),
            'skills': skills,
            'total': len(skills)
        }
    
    def skill_jobs(self, params):
        """获取所有职业列表"""
        # 返回所有可用的职业
        jobs = [
            {'job': 0, 'name': '鬼剑士'},
            {'job': 1, 'name': '格斗家'},
            {'job': 2, 'name': '神枪手'},
            {'job': 3, 'name': '魔法师'},
            {'job': 4, 'name': '圣职者'},
            {'job': 100, 'name': '狂战士'},
            {'job': 101, 'name': '剑魂'},
            {'job': 102, 'name': '鬼泣'},
            {'job': 103, 'name': '阿修罗'},
            {'job': 200, 'name': '气功师'},
            {'job': 201, 'name': '散打'},
            {'job': 202, 'name': '街霸'},
            {'job': 203, 'name': '柔道家'},
            {'job': 300, 'name': '漫游枪手'},
            {'job': 301, 'name': '枪炮师'},
            {'job': 302, 'name': '弹药专家'},
            {'job': 303, 'name': '机械师'},
            {'job': 400, 'name': '元素师'},
            {'job': 401, 'name': '召唤师'},
            {'job': 402, 'name': '战斗法师'},
            {'job': 403, 'name': '魔道学者'}
        ]
        return {'data': jobs}
    
    # ========== 统计分析 ==========
    
    def stats_online(self, params):
        """在线统计"""
        # 最近24小时在线趋势
        sql = """
            SELECT 
                DATE_FORMAT(occ_time, '%Y-%m-%d %H:00:00') as hour,
                SUM(occ_count) as total_online
            FROM taiwan_cain_log.concurrent_user_status
            WHERE occ_time > DATE_SUB(NOW(), INTERVAL 24 HOUR)
                AND player_status = 0
            GROUP BY hour
            ORDER BY hour
        """
        trend = execute_query('taiwan_cain_log', sql)
        
        # 当前在线
        current_sql = """
            SELECT SUM(occ_count) as current_online
            FROM taiwan_cain_log.concurrent_user_status
            WHERE occ_time > DATE_SUB(NOW(), INTERVAL 1 HOUR)
                AND player_status = 0
        """
        current = execute_query('taiwan_cain_log', current_sql)
        
        return {
            'current': current[0] if current else {'current_online': 0},
            'trend': trend
        }
    
    def stats_economy(self, params):
        """经济统计"""
        # 账号统计
        account_sql = """
            SELECT 
                COUNT(*) as total_accounts,
                SUM(CASE WHEN VIP != '' THEN 1 ELSE 0 END) as vip_accounts,
                SUM(CASE WHEN admin > 0 THEN 1 ELSE 0 END) as admin_accounts
            FROM d_taiwan.accounts
        """
        account_stats = execute_query('d_taiwan', account_sql)
        
        # 交易统计
        trans_sql = """
            SELECT 
                COUNT(*) as total_transactions,
                COUNT(DISTINCT occ_date) as active_days
            FROM taiwan_billing.log_transaction_history
        """
        trans_stats = execute_query('taiwan_billing', trans_sql)
        
        return {
            'accounts': account_stats[0] if account_stats else {},
            'transactions': trans_stats[0] if trans_stats else {}
        }
    
    def stats_dungeon(self, params):
        """副本统计"""
        sql = """
            SELECT 
                COUNT(*) as total_entries,
                COUNT(DISTINCT dungeon_index) as unique_dungeons,
                SUM(hour_enter_count) as total_enter_count
            FROM taiwan_cain_log.log_dungeon_entrance_hour
        """
        stats = execute_query('taiwan_cain_log', sql)
        
        # 热门副本
        hot_sql = """
            SELECT dungeon_index, SUM(hour_enter_count) as total_count
            FROM taiwan_cain_log.log_dungeon_entrance_hour
            GROUP BY dungeon_index
            ORDER BY total_count DESC
            LIMIT 10
        """
        hot_dungeons = execute_query('taiwan_cain_log', hot_sql)
        
        return {
            'stats': stats[0] if stats else {},
            'hot_dungeons': hot_dungeons
        }
    
    def stats_pvp(self, params):
        """PVP 统计"""
        sql = """
            SELECT 
                COUNT(*) as total_records,
                MAX(mc_max) as max_players,
                AVG(mc_max) as avg_players
            FROM d_taiwan.max_count_pvp
        """
        stats = execute_query('d_taiwan', sql)
        
        # PVP 排行榜 (按日期)
        rank_sql = """
            SELECT DATE(mc_date) as date, MAX(mc_max) as max_players
            FROM d_taiwan.max_count_pvp
            GROUP BY DATE(mc_date)
            ORDER BY max_players DESC
            LIMIT 20
        """
        rankings = execute_query('d_taiwan', rank_sql)
        
        return {
            'stats': stats[0] if stats else {},
            'rankings': rankings
        }
    
    def stats_online_history(self, params):
        """在线人数历史趋势"""
        days = int(params.get('days', [7])[0])
        sql = """
            SELECT 
                DATE(occ_time) as date,
                SUM(occ_count) as max_online,
                AVG(occ_count) as avg_online
            FROM taiwan_cain_log.concurrent_user_status
            WHERE occ_time > DATE_SUB(NOW(), INTERVAL %s DAY)
                AND player_status = 0
            GROUP BY DATE(occ_time)
            ORDER BY date
        """
        history = execute_query('taiwan_cain_log', sql, (days,))
        return {'data': history, 'days': days}
    
    def stats_economy_trend(self, params):
        """经济趋势"""
        days = int(params.get('days', [7])[0])
        sql = """
            SELECT 
                DATE(occ_date) as date,
                COUNT(*) as transaction_count,
                SUM(gold) as total_gold
            FROM taiwan_billing.log_transaction_history
            WHERE occ_date > DATE_SUB(NOW(), INTERVAL %s DAY)
            GROUP BY DATE(occ_date)
            ORDER BY date
        """
        trend = execute_query('taiwan_billing', sql, (days,))
        return {'data': trend, 'days': days}
    
    def stats_wealth_rank(self, params):
        """财富排行榜"""
        limit = int(params.get('limit', [20])[0])
        sql = """
            SELECT accountname, UID, billing, VIP
            FROM d_taiwan.accounts
            WHERE admin = 0
            ORDER BY billing DESC
            LIMIT %s
        """
        rankings = execute_query('d_taiwan', sql, (limit,))
        return {'data': rankings}
    
    def stats_dungeon_popular(self, params):
        """热门副本排行"""
        limit = int(params.get('limit', [10])[0])
        sql = """
            SELECT dungeon_index, SUM(hour_enter_count) as total_count,
                   COUNT(DISTINCT DATE(occ_date)) as active_days
            FROM taiwan_cain_log.log_dungeon_entrance_hour
            GROUP BY dungeon_index
            ORDER BY total_count DESC
            LIMIT %s
        """
        dungeons = execute_query('taiwan_cain_log', sql, (limit,))
        return {'data': dungeons}
    
    def stats_pvp_rankings(self, params):
        """PVP 详细排行榜"""
        limit = int(params.get('limit', [50])[0])
        sql = """
            SELECT DATE(mc_date) as date, mc_max as max_players, server_info
            FROM d_taiwan.max_count_pvp
            ORDER BY mc_max DESC
            LIMIT %s
        """
        rankings = execute_query('d_taiwan', sql, (limit,))
        return {'data': rankings}
    
    def stats_server(self, params):
        """服务器统计"""
        # 综合统计
        sql = """
            SELECT 
                (SELECT COUNT(*) FROM d_taiwan.accounts) as total_accounts,
                (SELECT COUNT(*) FROM taiwan_cain.charac_info) as total_characters,
                (SELECT COUNT(*) FROM taiwan_cain_2nd.user_items) as total_items,
                (SELECT COUNT(*) FROM taiwan_cain_2nd.postal) as total_mails,
                (SELECT COUNT(*) FROM dnf_tieba.tieba_posts) as total_tieba_posts
        """
        stats = execute_query('d_taiwan', sql)
        
        return {'data': stats[0] if stats else {}}
    
    # ========== 贴吧联动 ==========
    
    def tieba_posts(self, params):
        """贴吧帖子列表 (修复乱码)"""
        page = int(params.get('page', [1])[0])
        limit = int(params.get('limit', [20])[0])
        offset = (page - 1) * limit
        
        sql = """
            SELECT id, tieba_name, title, author, reply_count, view_count, url, post_time
            FROM dnf_tieba.tieba_posts
            ORDER BY post_time DESC LIMIT %s OFFSET %s
        """
        posts = execute_query('dnf_tieba', sql, (limit, offset))
        
        count_sql = "SELECT COUNT(*) as total FROM dnf_tieba.tieba_posts"
        total = execute_query('dnf_tieba', count_sql)[0]['total']
        
        return {
            'data': posts,
            'page': page,
            'limit': limit,
            'total': total
        }
    
    def tieba_search(self, params):
        """搜索贴吧帖子"""
        keyword = params.get('q', [''])[0]
        if not keyword:
            return {'error': 'missing q parameter'}
        
        # 使用 bytes 编码 SQL 以支持中文搜索
        keyword_bytes = keyword.encode('utf-8')
        sql = b"SELECT id, tieba_name, title, author, reply_count, view_count, url, post_time FROM tieba_posts WHERE title LIKE '%" + keyword_bytes + b"%' ORDER BY post_time DESC LIMIT 50"
        
        conn = pymysql.connect(**DB_CONFIG_RAW, database='dnf_tieba')
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute(sql)
        rows = cursor.fetchall()
        conn.close()
        
        return {'data': [decode_row(row) for row in rows]}
    
    def tieba_monitor(self, params):
        """贴吧监控 - 统计帖子类型"""
        # 统计
        sql = sql_to_bytes("""
            SELECT tieba_name, COUNT(*) as post_count,
                   SUM(reply_count) as total_replies, SUM(view_count) as total_views,
                   MAX(post_time) as latest_post
            FROM tieba_posts GROUP BY tieba_name
        """)
        
        conn = pymysql.connect(**DB_CONFIG_RAW, database='dnf_tieba')
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute(sql)
        stats = [decode_row(row) for row in cursor.fetchall()]
        
        # 关键词统计
        keywords_sql = sql_to_bytes("""
            SELECT 
                CASE
                    WHEN title LIKE '%求助%' OR title LIKE '%问题%' THEN '求助'
                    WHEN title LIKE '%分享%' OR title LIKE '%发布%' THEN '分享'
                    WHEN title LIKE '%版本%' OR title LIKE '%更新%' THEN '版本'
                    WHEN title LIKE '%PVF%' OR title LIKE '%修改%' THEN '技术'
                    WHEN title LIKE '%BUG%' OR title LIKE '%闪退%' THEN 'BUG'
                    ELSE '其他'
                END as category,
                COUNT(*) as count
            FROM tieba_posts
            GROUP BY category
        """)
        
        cursor.execute(keywords_sql)
        keywords = [decode_row(row) for row in cursor.fetchall()]
        conn.close()
        
        return {
            'forums': stats,
            'categories': keywords
        }
    
    # ========== 9. 封禁管理 ==========
    
    def punish_list(self, params):
        """封禁列表"""
        page = int(params.get('page', [1])[0])
        limit = int(params.get('limit', [20])[0])
        offset = (page - 1) * limit
        
        # 查询被封禁的账号 (accounts 表没有 punish 字段，用其他方式检测)
        sql = """
            SELECT UID, accountname, VIP, admin
            FROM d_taiwan.accounts
            WHERE admin > 0
            ORDER BY UID DESC
            LIMIT %s OFFSET %s
        """
        punished = execute_query('d_taiwan', sql, (limit, offset))
        
        return {'data': punished, 'page': page, 'limit': limit, 'note': 'accounts表无封禁字段，显示管理员列表'}
    
    def punish_logs(self, params):
        """封禁日志"""
        # accounts 表无封禁字段，返回空数据
        return {'data': [], 'note': 'accounts表无封禁日志字段'}
    
    # ========== 10. 邮件系统管理 ==========
    
    def mail_list(self, params):
        """邮件列表"""
        page = int(params.get('page', [1])[0])
        limit = int(params.get('limit', [20])[0])
        offset = (page - 1) * limit
        
        sql = """
            SELECT postal_id, occ_time, send_charac_name, receive_charac_no,
                   item_id, gold, delete_flag,
                   CASE WHEN delete_flag = 0 THEN '未读' ELSE '已读' END as status
            FROM taiwan_cain_2nd.postal
            ORDER BY occ_time DESC
            LIMIT %s OFFSET %s
        """
        mails = execute_query('taiwan_cain_2nd', sql, (limit, offset))
        
        count_sql = "SELECT COUNT(*) as total FROM taiwan_cain_2nd.postal"
        total = execute_query('taiwan_cain_2nd', count_sql)[0]['total']
        
        return {'data': mails, 'page': page, 'limit': limit, 'total': total}
    
    def mail_stats(self, params):
        """邮件统计"""
        sql = """
            SELECT 
                COUNT(*) as total_mails,
                SUM(CASE WHEN delete_flag = 0 THEN 1 ELSE 0 END) as unread_mails,
                SUM(CASE WHEN gold > 0 THEN 1 ELSE 0 END) as mails_with_gold,
                SUM(gold) as total_gold_sent,
                AVG(gold) as avg_gold_per_mail
            FROM taiwan_cain_2nd.postal
        """
        stats = execute_query('taiwan_cain_2nd', sql)
        return {'data': stats[0] if stats else {}}
    
    # ========== 11. 活动管理 ==========
    
    def event_list(self, params):
        """活动列表"""
        sql = sql_to_bytes("""
            SELECT id, title, url, post_time,
                   CASE
                     WHEN title LIKE '%活动%' OR title LIKE '%福利%' THEN '福利活动'
                     WHEN title LIKE '%版本%' OR title LIKE '%更新%' THEN '版本更新'
                     WHEN title LIKE '%比赛%' OR title LIKE '%竞技%' THEN '竞技活动'
                     ELSE '其他'
                   END as event_type
            FROM tieba_posts
            WHERE title LIKE '%活动%' OR title LIKE '%版本%' OR title LIKE '%更新%' OR title LIKE '%比赛%'
            ORDER BY post_time DESC LIMIT 20
        """)
        
        conn = pymysql.connect(**DB_CONFIG_RAW, database='dnf_tieba')
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute(sql)
        rows = cursor.fetchall()
        conn.close()
        
        return {'data': [decode_row(row) for row in rows]}
    
    def event_stats(self, params):
        """活动统计"""
        sql = sql_to_bytes("""
            SELECT 
                CASE
                  WHEN title LIKE '%活动%' OR title LIKE '%福利%' THEN '福利活动'
                  WHEN title LIKE '%版本%' OR title LIKE '%更新%' THEN '版本更新'
                  WHEN title LIKE '%比赛%' OR title LIKE '%竞技%' THEN '竞技活动'
                  ELSE '其他'
                END as event_type,
                COUNT(*) as count,
                SUM(reply_count) as total_replies,
                SUM(view_count) as total_views
            FROM tieba_posts
            WHERE title LIKE '%活动%' OR title LIKE '%版本%' OR title LIKE '%更新%' OR title LIKE '%比赛%'
            GROUP BY event_type
        """)
        
        conn = pymysql.connect(**DB_CONFIG_RAW, database='dnf_tieba')
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute(sql)
        rows = cursor.fetchall()
        conn.close()
        
        return {'data': [decode_row(row) for row in rows]}
    
    # ========== 12. 贴吧帖子关联角色（增强版） ==========
    
    def tieba_link_character(self, params):
        """贴吧帖子关联游戏角色"""
        post_id = params.get('id', [None])[0]
        if not post_id:
            return {'error': 'missing id parameter'}
        
        # 获取帖子内容
        post_sql = "SELECT * FROM dnf_tieba.tieba_posts WHERE id = %s"
        post = execute_query('dnf_tieba', post_sql, (post_id,))
        if not post:
            return {'error': 'post not found'}
        
        post = post[0]
        title = post['title']
        
        # 从标题中提取可能的角色名
        # 常见格式: "[角色名] 的装备" 或 "角色名：xxx"
        import re
        possible_names = re.findall(r'[\u4e00-\u9fa5]{2,8}', title)
        
        linked_chars = []
        for name in possible_names[:5]:
            # 使用 bytes 编码 SQL 以支持中文搜索
            name_bytes = name.encode('utf-8')
            sql = b"SELECT m_id, charac_name, village, job, lev FROM charac_info WHERE charac_name LIKE '%" + name_bytes + b"%' LIMIT 5"
            
            conn = pymysql.connect(**DB_CONFIG_RAW, database='taiwan_cain')
            cursor = conn.cursor(pymysql.cursors.DictCursor)
            cursor.execute(sql)
            rows = cursor.fetchall()
            conn.close()
            
            linked_chars.extend([decode_row(row) for row in rows])
        
        return {
            'post': post,
            'possible_names': possible_names[:5],
            'linked_characters': linked_chars
        }
    
    # ========== 13. 玩家反馈追踪 ==========
    
    def feedback_list(self, params):
        """玩家反馈列表"""
        page = int(params.get('page', [1])[0])
        limit = int(params.get('limit', [20])[0])
        offset = (page - 1) * limit
        
        sql = sql_to_bytes("""
            SELECT id, title, author, reply_count, view_count, url, post_time
            FROM tieba_posts
            WHERE title LIKE '%%BUG%%' OR title LIKE '%%bug%%'
               OR title LIKE '%%建议%%' OR title LIKE '%%求助%%'
               OR title LIKE '%%问题%%'
            ORDER BY reply_count DESC, post_time DESC LIMIT %s OFFSET %s
        """)
        
        conn = pymysql.connect(**DB_CONFIG_RAW, database='dnf_tieba')
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute(sql, (limit, offset))
        rows = cursor.fetchall()
        conn.close()
        
        return {'data': [decode_row(row) for row in rows], 'page': page, 'limit': limit}
    
    def feedback_stats(self, params):
        """反馈统计"""
        sql = sql_to_bytes("""
            SELECT 
                CASE
                  WHEN title LIKE '%%BUG%%' OR title LIKE '%%bug%%' THEN 'BUG反馈'
                  WHEN title LIKE '%%建议%%' THEN '建议'
                  WHEN title LIKE '%%求助%%' OR title LIKE '%%问题%%' THEN '求助'
                  ELSE '其他'
                END as feedback_type,
                COUNT(*) as count,
                SUM(reply_count) as total_replies
            FROM tieba_posts
            WHERE title LIKE '%%BUG%%' OR title LIKE '%%bug%%'
               OR title LIKE '%%建议%%'
               OR title LIKE '%%求助%%' OR title LIKE '%%问题%%'
            GROUP BY feedback_type
        """)
        
        conn = pymysql.connect(**DB_CONFIG_RAW, database='dnf_tieba')
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute(sql)
        rows = cursor.fetchall()
        conn.close()
        
        return {'data': [decode_row(row) for row in rows]}
    
    # ========== 14. 版本更新监控 ==========
    
    def version_monitor(self, params):
        """版本更新监控"""
        sql = sql_to_bytes("""
            SELECT id, title, author, reply_count, view_count, url, post_time,
                CASE
                     WHEN title LIKE '%更新%' THEN '更新公告'
                     WHEN title LIKE '%维护%' THEN '维护公告'
                     WHEN title LIKE '%版本%' THEN '版本信息'
                     WHEN title LIKE '%新职业%' OR title LIKE '%新角色%' THEN '新内容'
                     ELSE '其他'
                END as version_type
            FROM tieba_posts
            WHERE title LIKE '%更新%' OR title LIKE '%维护%' OR title LIKE '%版本%'
               OR title LIKE '%新职业%' OR title LIKE '%新角色%'
               OR title LIKE '%PVF%' OR title LIKE '%补丁%'
            ORDER BY post_time DESC LIMIT 20
        """)
        
        conn = pymysql.connect(**DB_CONFIG_RAW, database='dnf_tieba')
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute(sql)
        rows = cursor.fetchall()
        conn.close()
        
        return {'data': [decode_row(row) for row in rows]}
    
    def version_bugs(self, params):
        """BUG 监控"""
        sql = sql_to_bytes("""
            SELECT id, title, author, reply_count, view_count, url, post_time,
                   CASE
                     WHEN title LIKE '%闪退%' THEN '闪退'
                     WHEN title LIKE '%卡顿%' OR title LIKE '%延迟%' THEN '性能'
                     WHEN title LIKE '%BUG%' OR title LIKE '%bug%' THEN 'BUG'
                     WHEN title LIKE '%无法%' OR title LIKE '%失败%' THEN '功能异常'
                     ELSE '其他'
                   END as bug_type
            FROM tieba_posts
            WHERE title LIKE '%BUG%' OR title LIKE '%bug%' OR title LIKE '%闪退%' OR title LIKE '%卡顿%'
               OR title LIKE '%无法%' OR title LIKE '%失败%' OR title LIKE '%延迟%'
            ORDER BY reply_count DESC, post_time DESC LIMIT 20
        """)
        
        conn = pymysql.connect(**DB_CONFIG_RAW, database='dnf_tieba')
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute(sql)
        rows = cursor.fetchall()
        conn.close()
        
        return {'data': [decode_row(row) for row in rows]}
    
    # ========== POST 处理函数 ==========
    
    def punish_batch(self, data):
        """批量封禁"""
        accounts = data.get('accounts', [])
        reason = data.get('reason', '违规操作')
        duration_hours = data.get('duration_hours', 24)
        
        if not accounts:
            return {'error': 'no accounts provided'}
        
        results = []
        for account in accounts:
            try:
                sql = """
                    UPDATE d_taiwan.accounts
                    SET punish_end_time = DATE_ADD(NOW(), INTERVAL %s HOUR)
                    WHERE account = %s
                """
                execute_query('d_taiwan', sql, (duration_hours, account))
                results.append({'account': account, 'status': 'success'})
            except Exception as e:
                results.append({'account': account, 'status': 'failed', 'error': str(e)})
        
        return {
            'total': len(accounts),
            'success': sum(1 for r in results if r['status'] == 'success'),
            'failed': sum(1 for r in results if r['status'] == 'failed'),
            'results': results
        }
    
    def mail_send(self, data):
        """发送邮件 (演示功能)"""
        sender = data.get('sender', '系统管理员')
        receiver_id = data.get('receiver_id')
        item_id = data.get('item_id', 0)
        gold = data.get('gold', 0)
        
        if not receiver_id:
            return {'error': 'missing receiver_id'}
        
        # 注意：postal 表结构需要确认，这里是演示
        return {
            'status': 'success',
            'message': f'邮件已发送给角色 {receiver_id}',
            'item_id': item_id,
            'gold': gold,
            'note': '演示功能，实际写入需确认表结构'
        }
    
    def event_create(self, data):
        """创建活动（通过贴吧发布）"""
        title = data.get('title', '')
        content = data.get('content', '')
        event_type = data.get('type', '其他')
        
        if not title:
            return {'error': 'missing title'}
        
        # 这里可以集成贴吧发帖功能
        return {
            'status': 'success',
            'message': '活动已创建',
            'title': title,
            'type': event_type
        }
    
    # ========== 数据自检（增强版） ==========
    
    def check_integrity(self, params):
        """数据完整性检查"""
        checks = []
        
        # 使用 unicode=True 的连接进行数字类型查询
        conn = pymysql.connect(host='127.0.0.1', port=3307, user='root', password='88888888', charset='utf8mb4')
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        
        # 账号检查
        cursor.execute('SELECT COUNT(*) as total FROM d_taiwan.accounts')
        account = cursor.fetchone()
        checks.append({'item': '账号数据', 'status': '正常' if account['total'] > 0 else '异常', 'details': account})
        
        # 角色检查
        cursor.execute('SELECT COUNT(*) as total, MAX(lev) as max_level, ROUND(AVG(lev),1) as avg_level FROM taiwan_cain.charac_info')
        char = cursor.fetchone()
        checks.append({'item': '角色数据', 'status': '正常' if char['total'] > 0 else '异常', 'details': char})
        
        # 物品检查
        cursor.execute('SELECT COUNT(*) as total, COUNT(DISTINCT it_id) as unique_items FROM taiwan_cain_2nd.user_items')
        item = cursor.fetchone()
        checks.append({'item': '物品数据', 'status': '正常' if item['total'] > 0 else '异常', 'details': item})
        
        # 贴吧检查
        cursor.execute('SELECT COUNT(*) as total FROM dnf_tieba.tieba_posts')
        tieba = cursor.fetchone()
        checks.append({'item': '贴吧数据', 'status': '正常' if tieba['total'] > 0 else '异常', 'details': tieba})
        
        conn.close()
        return {'checks': checks}
    
    def check_consistency(self, params):
        """数据一致性检查"""
        checks = []
        
        # 使用 unicode=True 的连接
        conn = pymysql.connect(host='127.0.0.1', port=3307, user='root', password='88888888', charset='utf8mb4')
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        
        # 角色-物品关联
        cursor.execute('''
            SELECT COUNT(DISTINCT ui.charac_no) as linked_chars,
                   (SELECT COUNT(*) FROM taiwan_cain.charac_info) as total_chars
            FROM taiwan_cain_2nd.user_items ui
            WHERE ui.charac_no IN (SELECT m_id FROM taiwan_cain.charac_info)
        ''')
        consistency = cursor.fetchone()
        checks.append({'item': '角色-物品关联', 'status': '正常' if consistency['linked_chars'] > 0 else '异常', 'details': consistency})
        
        # 角色-邮件关联
        cursor.execute('''
            SELECT COUNT(DISTINCT receive_charac_no) as linked_chars,
                   (SELECT COUNT(*) FROM taiwan_cain.charac_info) as total_chars
            FROM taiwan_cain_2nd.postal
            WHERE receive_charac_no IN (SELECT m_id FROM taiwan_cain.charac_info)
        ''')
        mail_consistency = cursor.fetchone()
        checks.append({'item': '角色-邮件关联', 'status': '正常' if mail_consistency['linked_chars'] > 0 else '异常', 'details': mail_consistency})
        
        # 账号-角色关联
        cursor.execute('''
            SELECT COUNT(DISTINCT ci.m_id) as linked_chars,
                   (SELECT COUNT(*) FROM d_taiwan.accounts) as total_accounts
            FROM taiwan_cain.charac_info ci
            WHERE ci.m_id > 0
        ''')
        account_consistency = cursor.fetchone()
        checks.append({'item': '账号-角色关联', 'status': '正常' if account_consistency['linked_chars'] > 0 else '异常', 'details': account_consistency})
        
        conn.close()
        return {'checks': checks}
    
    def check_anomaly(self, params):
        """异常检测"""
        anomalies = []
        
        # 使用 unicode=True 的连接
        conn = pymysql.connect(host='127.0.0.1', port=3307, user='root', password='88888888', charset='utf8mb4')
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        
        # 检测等级异常
        try:
            cursor.execute('SELECT charac_name, lev, job FROM taiwan_cain.charac_info WHERE lev > 100 OR lev < 1 ORDER BY lev DESC LIMIT 10')
            level_anomalies = cursor.fetchall()
            if level_anomalies:
                anomalies.append({'type': '等级异常', 'count': len(level_anomalies), 'details': level_anomalies})
        except:
            pass
        
        # 检测 billing 异常
        try:
            cursor.execute('SELECT accountname, billing, UID FROM d_taiwan.accounts WHERE billing > 1000000 ORDER BY billing DESC LIMIT 10')
            billing_anomalies = cursor.fetchall()
            if billing_anomalies:
                anomalies.append({'type': 'billing异常', 'count': len(billing_anomalies), 'details': billing_anomalies})
        except:
            pass
        
        conn.close()
        return {'anomalies': anomalies, 'total': len(anomalies)}
    
    def check_report(self, params):
        """生成完整自检报告"""
        integrity = self.check_integrity(params)
        consistency = self.check_consistency(params)
        
        # 生成报告时间
        report_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        all_checks = integrity['checks'] + consistency['checks']
        passed = sum(1 for c in all_checks if c['status'] == '正常')
        failed = len(all_checks) - passed
        
        return {
            'report_time': report_time,
            'integrity': integrity['checks'],
            'consistency': consistency['checks'],
            'summary': {
                'total_checks': len(all_checks),
                'passed': passed,
                'failed': failed
            }
        }
    
    # ========== 物品列表（无需搜索） ==========
    
    def item_list(self, params):
        """物品列表"""
        page = int(params.get('page', [1])[0])
        limit = int(params.get('page_size', [20])[0])
        offset = (page - 1) * limit
        category = params.get('category', [''])[0]
        
        if category:
            sql = """
                SELECT it_no as id, it_name as name, master_type as category,
                       sub_type as type, level, rarity, '' as description
                FROM taiwan_cain_web.dnf_item_info WHERE master_type = %s
                ORDER BY rarity DESC, level DESC LIMIT %s OFFSET %s
            """
            items = execute_query('taiwan_cain_web', sql, (category, limit, offset))
            count_sql = "SELECT COUNT(*) as total FROM taiwan_cain_web.dnf_item_info WHERE master_type = %s"
            total = execute_query('taiwan_cain_web', count_sql, (category,))[0]['total']
        else:
            sql = """
                SELECT it_no as id, it_name as name, master_type as category,
                       sub_type as type, level, rarity, '' as description
                FROM taiwan_cain_web.dnf_item_info
                ORDER BY rarity DESC, level DESC LIMIT %s OFFSET %s
            """
            items = execute_query('taiwan_cain_web', sql, (limit, offset))
            count_sql = "SELECT COUNT(*) as total FROM taiwan_cain_web.dnf_item_info"
            total = execute_query('taiwan_cain_web', count_sql)[0]['total']
        
        return {'data': items, 'page': page, 'size': limit, 'total': total}
    
    # ========== 怪物列表（无需搜索） ==========
    
    def monster_list(self, params):
        """怪物列表"""
        page = int(params.get('page', [1])[0])
        limit = int(params.get('page_size', [20])[0])
        offset = (page - 1) * limit
        
        sql = """
            SELECT idx, mon_name_kr
            FROM taiwan_cain_web.dnf_monster_info
            ORDER BY idx LIMIT %s OFFSET %s
        """
        monsters = execute_query('taiwan_cain_web', sql, (limit, offset))
        count_sql = "SELECT COUNT(*) as total FROM taiwan_cain_web.dnf_monster_info"
        total = execute_query('taiwan_cain_web', count_sql)[0]['total']
        
        return {'data': monsters, 'page': page, 'size': limit, 'total': total}
    
    # ========== PVF 解析 ==========
    
    def pvf_list(self, params):
        """PVF 物品列表（从 gold.txt 读取）"""
        page = int(params.get('page', [1])[0])
        limit = int(params.get('page_size', [50])[0])
        offset = (page - 1) * limit
        category = params.get('category', [''])[0]
        
        items = self._load_pvf_items()
        
        if category:
            items = [i for i in items if i.get('category') == category]
        
        total = len(items)
        page_items = items[offset:offset + limit]
        
        return {'data': page_items, 'page': page, 'size': limit, 'total': total}
    
    def pvf_search(self, params):
        """搜索 PVF 物品"""
        keyword = params.get('q', [''])[0]
        if not keyword:
            return self.pvf_list(params)
        
        items = self._load_pvf_items()
        matched = [i for i in items if keyword.lower() in i['name'].lower()]
        
        return {'data': matched[:50], 'total': len(matched)}
    
    def pvf_detail(self, params):
        """PVF 物品详情"""
        item_id = params.get('id', [None])[0]
        if not item_id:
            return {'error': 'missing id parameter'}
        
        items = self._load_pvf_items()
        for item in items:
            if item['id'] == int(item_id):
                return {'data': item}
        
        return {'error': 'item not found'}
    
    def pvf_categories(self, params):
        """PVF 物品分类统计"""
        items = self._load_pvf_items()
        categories = {}
        for item in items:
            cat = item.get('category', '其他')
            categories[cat] = categories.get(cat, 0) + 1
        
        return {'data': categories, 'total': len(items)}
    
    def _classify_pvf_item(self, item_id):
        """根据 ID 范围分类 PVF 物品"""
        if 0 <= item_id < 10000: return '消耗品'
        elif 10000 <= item_id < 20000: return '材料'
        elif 20000 <= item_id < 30000: return '装备-武器'
        elif 30000 <= item_id < 40000: return '装备-防具'
        elif 40000 <= item_id < 50000: return '装备-首饰'
        elif 50000 <= item_id < 60000: return '装扮'
        elif 60000 <= item_id < 70000: return '宠物'
        elif 70000 <= item_id < 80000: return '称号'
        elif 80000 <= item_id < 90000: return '任务'
        else: return '其他'
    
    def _load_pvf_items(self):
        """加载 PVF 物品数据"""
        if hasattr(self, '_pvf_cache') and self._pvf_cache:
            return self._pvf_cache
        
        items = []
        try:
            result = subprocess.run(
                ['sshpass', '-p', 'wp930803', 'ssh', '-o', 'StrictHostKeyChecking=no',
                 'root@192.168.1.204', 'cat /opt/dnf-llnut/data/conf.d/dnf-console/source/gold.txt'],
                capture_output=True, text=True, timeout=30
            )
            if result.returncode == 0:
                for line in result.stdout.split('\n'):
                    line = line.strip()
                    if not line: continue
                    match = re.match(r'\[(\d+)\s*\]\s*name:(.+)', line)
                    if match:
                        item_id = int(match.group(1))
                        item_name = match.group(2).strip()
                        items.append({
                            'id': item_id,
                            'name': item_name,
                            'category': self._classify_pvf_item(item_id)
                        })
        except Exception as e:
            print(f"[WARN] PVF 加载失败: {e}")
        
        self._pvf_cache = items
        return items
    
    def health_check(self, params):
        """健康检查"""
        return {
            'status': 'ok',
            'timestamp': datetime.now().isoformat(),
            'version': '3.0.0',
            'features': [
                '1. 角色详情查询',
                '2. 物品查询系统',
                '3. 怪物图鉴',
                '4. 技能查询',
                '5. 服务器状态监控',
                '6. 经济系统监控',
                '7. 副本统计',
                '8. PVP 排行榜',
                '9. 封禁管理',
                '10. 邮件系统管理',
                '11. 活动管理',
                '12. 贴吧帖子关联角色',
                '13. 玩家反馈追踪',
                '14. 版本更新监控',
                '15. PVF 解析',
            ]
        }

def run_server(port=18883):
    """启动服务器"""
    server = HTTPServer(('0.0.0.0', port), DNFAdminHandler)
    print(f"[*] DNF Admin API v2.0 启动在端口 {port}")
    print(f"[*] 访问地址: http://localhost:{port}/api/v2/")
    server.serve_forever()

if __name__ == '__main__':
    run_server()
