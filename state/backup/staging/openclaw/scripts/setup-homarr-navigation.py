#!/usr/bin/env python3
"""
Homarr 导航页配置生成脚本
根据设计稿自动创建首页和分组
"""
import sqlite3
import uuid
import json
import time
import hashlib

DB_PATH = '/var/lib/docker/volumes/96a3f0d55823beaad0d560110fbbe7aff96b578add110c792643b701c53eb390/_data/db/db.sqlite'
USER_ID = 'znqe1euzxiahtjszuh9rlvxe'

# 首页10个常用直达服务
QUICK_ACCESS_SERVICES = [
    {"name": "影音中心", "name_en": "Jellyfin", "url": "http://192.168.1.212:8096", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/jellyfin.svg", "desc": "媒体服务器"},
    {"name": "媒体请求", "name_en": "Jellyseerr", "url": "http://192.168.1.212:5055", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/jellyseerr.svg", "desc": "媒体请求管理"},
    {"name": "下载管理", "name_en": "qBittorrent", "url": "http://192.168.1.212:8080", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/qbittorrent.svg", "desc": "BT下载客户端"},
    {"name": "剧集管理", "name_en": "Sonarr", "url": "http://192.168.1.212:8989", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/sonarr.svg", "desc": "电视剧自动化"},
    {"name": "智能中枢", "name_en": "OpenClaw", "url": "http://192.168.1.212:18789", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/openclaw.svg", "desc": "AI智能助手"},
    {"name": "控制台", "name_en": "ClawPanel", "url": "http://192.168.1.212:18888", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/openclaw.svg", "desc": "OpenClaw控制面板"},
    {"name": "系统面板", "name_en": "1Panel", "url": "http://192.168.1.212:10002", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/1panel.svg", "desc": "服务器管理面板"},
    {"name": "反向代理", "name_en": "Lucky", "url": "http://192.168.1.212:16601", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/lucky.svg", "desc": "反向代理管理"},
    {"name": "AI对话", "name_en": "OpenWebUI", "url": "http://192.168.1.212:3000", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/open-webui.svg", "desc": "AI对话界面"},
    {"name": "索引中心", "name_en": "Prowlarr", "url": "http://192.168.1.212:9696", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/prowlarr.svg", "desc": "索引器管理"},
]

# 四大分组及其服务
CATEGORY_SERVICES = {
    "媒体娱乐": [
        {"name": "影音中心", "name_en": "Jellyfin", "url": "http://192.168.1.212:8096", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/jellyfin.svg"},
        {"name": "媒体请求", "name_en": "Jellyseerr", "url": "http://192.168.1.212:5055", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/jellyseerr.svg"},
        {"name": "下载管理", "name_en": "qBittorrent", "url": "http://192.168.1.212:8080", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/qbittorrent.svg"},
        {"name": "剧集管理", "name_en": "Sonarr", "url": "http://192.168.1.212:8989", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/sonarr.svg"},
        {"name": "电影管理", "name_en": "Radarr", "url": "http://192.168.1.212:7878", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/radarr.svg"},
        {"name": "字幕管理", "name_en": "Bazarr", "url": "http://192.168.1.212:6767", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/bazarr.svg"},
        {"name": "索引中心", "name_en": "Prowlarr", "url": "http://192.168.1.212:9696", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/prowlarr.svg"},
        {"name": "索引源", "name_en": "Jackett", "url": "http://192.168.1.212:9117", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/jackett.svg"},
        {"name": "媒体库", "name_en": "Stash", "url": "http://192.168.1.212:9999", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/stash.svg"},
    ],
    "AI助手": [
        {"name": "智能中枢", "name_en": "OpenClaw", "url": "http://192.168.1.212:18789", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/openclaw.svg"},
        {"name": "控制台", "name_en": "ClawPanel", "url": "http://192.168.1.212:18888", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/openclaw.svg"},
        {"name": "AI对话", "name_en": "OpenWebUI", "url": "http://192.168.1.212:3000", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/open-webui.svg"},
    ],
    "系统运维": [
        {"name": "系统面板", "name_en": "1Panel", "url": "http://192.168.1.212:10002", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/1panel.svg"},
        {"name": "虚拟化", "name_en": "Proxmox", "url": "https://192.168.1.212:8006", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/proxmox.svg"},
        {"name": "存储管理", "name_en": "TrueNAS", "url": "http://192.168.1.212:5000", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/truenas.svg"},
        {"name": "博客", "name_en": "Halo", "url": "http://192.168.1.212:8090", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/halo.svg"},
    ],
    "网络代理": [
        {"name": "反向代理", "name_en": "Lucky", "url": "http://192.168.1.212:16601", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/lucky.svg"},
        {"name": "主路由", "name_en": "OpenWrt", "url": "http://192.168.1.1", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/openwrt.svg"},
        {"name": "异地组网", "name_en": "EasyTier", "url": "http://192.168.1.212:11211", "icon": "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/svg/network.svg"},
    ],
}

def generate_id():
    """生成Homarr兼容的ID"""
    return uuid.uuid4().hex[:24]

def create_app(cur, name, name_en, url, icon, desc=""):
    """创建应用"""
    app_id = generate_id()
    cur.execute('''
        INSERT INTO app (id, name, description, icon_url, href, ping_url)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (app_id, f"{name} / {name_en}", desc, icon, url, url))
    return app_id

def create_board(cur, name, user_id, is_public=False):
    """创建板块"""
    board_id = generate_id()
    cur.execute('''
        INSERT INTO board (id, name, is_public, creator_id, page_title, meta_title,
                          primary_color, secondary_color, opacity, item_radius, disable_status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (board_id, name, is_public, user_id, name, name,
          '#3b82f6', '#60a5fa', 100, 'lg', False))
    return board_id

def create_layout(cur, board_id, name, column_count, breakpoint=0):
    """创建布局"""
    layout_id = generate_id()
    cur.execute('''
        INSERT INTO layout (id, name, board_id, column_count, breakpoint)
        VALUES (?, ?, ?, ?, ?)
    ''', (layout_id, name, board_id, column_count, breakpoint))
    return layout_id

def create_section(cur, board_id, name, kind="category"):
    """创建分区"""
    section_id = generate_id()
    cur.execute('''
        INSERT INTO section (id, board_id, kind, name, options)
        VALUES (?, ?, ?, ?, ?)
    ''', (section_id, board_id, kind, name, '{"json": {}}'))
    return section_id

def create_section_layout(cur, section_id, layout_id, x, y, width, height):
    """创建分区布局"""
    cur.execute('''
        INSERT INTO section_layout (section_id, layout_id, x_offset, y_offset, width, height)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (section_id, layout_id, x, y, width, height))

def create_item(cur, board_id, app_id, kind="app"):
    """创建项目"""
    item_id = generate_id()
    cur.execute('''
        INSERT INTO item (id, board_id, kind, options, advanced_options)
        VALUES (?, ?, ?, ?, ?)
    ''', (item_id, board_id, kind, 
          f'{{"json":{{"appId":"{app_id}"}}}}',
          '{"json":{}}'))
    return item_id

def create_item_layout(cur, item_id, section_id, layout_id, x, y, width, height):
    """创建项目布局"""
    cur.execute('''
        INSERT INTO item_layout (item_id, section_id, layout_id, x_offset, y_offset, width, height)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', (item_id, section_id, layout_id, x, y, width, height))

def main():
    con = sqlite3.connect(DB_PATH)
    cur = con.cursor()
    
    print("开始创建导航页...")
    
    # 1. 创建主板块（首页）
    board_id = create_board(cur, "Bandas Hub", USER_ID, is_public=True)
    print(f"✓ 创建主板块: {board_id}")
    
    # 2. 创建布局（桌面端）
    desktop_layout = create_layout(cur, board_id, "Desktop", 12, 1200)
    print(f"✓ 创建桌面布局: {desktop_layout}")
    
    # 3. 创建快速访问分区
    quick_section = create_section(cur, board_id, "常用直达", "category")
    create_section_layout(cur, quick_section, desktop_layout, 0, 0, 12, 1)
    print(f"✓ 创建快速访问分区: {quick_section}")
    
    # 4. 创建10个常用直达服务
    for idx, service in enumerate(QUICK_ACCESS_SERVICES):
        app_id = create_app(cur, service["name"], service["name_en"], 
                           service["url"], service["icon"], service.get("desc", ""))
        item_id = create_item(cur, board_id, app_id)
        
        # 计算位置 (每行5个，共2行)
        row = idx // 5
        col = idx % 5
        x = col * 2 + 1
        y = row + 1
        
        create_item_layout(cur, item_id, quick_section, desktop_layout, x, y, 2, 1)
        print(f"  ✓ {service['name']} / {service['name_en']}")
    
    # 5. 创建四大分组分区
    category_y = 4
    for cat_name, services in CATEGORY_SERVICES.items():
        cat_section = create_section(cur, board_id, cat_name, "category")
        create_section_layout(cur, cat_section, desktop_layout, 0, category_y, 12, 1)
        print(f"✓ 创建分组: {cat_name}")
        
        for idx, service in enumerate(services):
            app_id = create_app(cur, service["name"], service["name_en"],
                               service["url"], service["icon"])
            item_id = create_item(cur, board_id, app_id)
            
            row = idx // 6
            col = idx % 6
            x = col * 2
            y = category_y + 1 + row
            
            create_item_layout(cur, item_id, cat_section, desktop_layout, x, y, 2, 1)
        
        category_y += 1 + ((len(services) + 5) // 6)
    
    # 6. 更新用户的home_board_id
    cur.execute('UPDATE user SET home_board_id = ? WHERE id = ?', (board_id, USER_ID))
    print(f"✓ 设置用户默认板块")
    
    # 7. 更新服务器设置
    cur.execute('UPDATE serverSetting SET value = ? WHERE setting_key = ?', 
                (json.dumps({"json": {"homeBoardId": board_id, "mobileHomeBoardId": board_id}}), 'board'))
    print(f"✓ 更新服务器设置")
    
    # 8. 完成onboarding
    cur.execute('DELETE FROM onboarding')
    cur.execute('INSERT INTO onboarding (id, step) VALUES (?, ?)', (generate_id(), 'completed'))
    print(f"✓ 完成初始化向导")
    
    con.commit()
    con.close()
    
    print("\n✅ 导航页配置完成！")
    print(f"访问地址: http://192.168.1.212:7575")
    print(f"用户名: bandas")
    print(f"密码: 使用你之前设置的密码或运行: docker exec homarr node /app/apps/cli/cli.cjs users update-password -u bandas")

if __name__ == '__main__':
    main()
