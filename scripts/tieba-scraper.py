#!/usr/bin/env python3
"""
百度贴吧帖子抓取 + 导入一体化脚本
用法: python3 tieba-scraper.py "台服dnf" --pages 3 --import
"""
import requests
import json
import time
import sys
import argparse
import re
import subprocess
from datetime import datetime
from urllib.parse import quote

def scrape_tieba_forum(forum_name, max_pages=3):
    """抓取贴吧论坛帖子"""
    posts = []
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Cookie': 'BAIDUID=ABCDEF1234567890',
    }
    
    for page in range(1, max_pages + 1):
        try:
            url = f"https://tieba.baidu.com/mo/q/m?kw={quote(forum_name)}&pn={(page-1)*50}"
            print(f"[*] 抓取第 {page} 页: {url}")
            
            resp = requests.get(url, headers=headers, timeout=15)
            if resp.status_code == 200:
                html = resp.text
                
                # 提取帖子数据
                pattern = r'"title"\s*:\s*"([^"]+)".*?"tid"\s*:\s*(\d+)'
                matches = re.findall(pattern, html, re.DOTALL)
                
                if matches:
                    for title, tid in matches:
                        try:
                            title = title.encode().decode('unicode_escape')
                        except:
                            pass
                        
                        post = {
                            'tid': tid,
                            'title': title,
                            'url': f'https://tieba.baidu.com/p/{tid}',
                            'scraped_at': datetime.now().isoformat(),
                        }
                        posts.append(post)
                        print(f"  [+] {title[:60]} (tid:{tid})")
                    
                    print(f"  [OK] 第 {page} 页提取到 {len(matches)} 条帖子")
                else:
                    print(f"  [!] 未找到帖子数据")
            else:
                print(f"  [ERR] HTTP {resp.status_code}")
            
            time.sleep(2)
            
        except Exception as e:
            print(f"  [ERR] {e}")
    
    return posts

def import_to_db(posts, forum_name):
    """通过 SSH 导入到数据库"""
    # 构建 SQL
    values = []
    for p in posts:
        title = p['title'].replace("'", "\\'").replace('"', '\\"')
        url = p['url']
        values.append(f"('{forum_name}', '{title}', '', 0, 0, '{url}', NOW())")
    
    sql = f"""
INSERT INTO dnf_tieba.tieba_posts (tieba_name, title, author, reply_count, view_count, url, post_time)
VALUES {','.join(values)};
"""
    
    # 通过 SSH 执行
    cmd = f'sshpass -p wp930803 ssh -o StrictHostKeyChecking=no root@192.168.1.204 "docker exec dnf-llnut_dnf-1_1 mysql -u root -p88888888 -e \\\"{sql}\\\""'
    
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        print(f"[OK] 成功导入 {len(posts)} 条帖子到数据库")
    else:
        print(f"[ERR] 导入失败: {result.stderr}")

def save_to_json(posts, filename):
    """保存到JSON文件"""
    # 清理无效的 Unicode 字符
    for p in posts:
        p['title'] = p['title'].encode('utf-8', errors='ignore').decode('utf-8')
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(posts, f, ensure_ascii=False, indent=2)
    print(f"\n[OK] 已保存 {len(posts)} 条帖子到 {filename}")

def main():
    parser = argparse.ArgumentParser(description='百度贴吧帖子抓取器')
    parser.add_argument('forum', help='贴吧名称 (如: 台服dnf)')
    parser.add_argument('--pages', type=int, default=3, help='抓取页数 (默认3)')
    parser.add_argument('--output', '-o', help='输出文件名')
    parser.add_argument('--import-db', action='store_true', help='导入到数据库')
    
    args = parser.parse_args()
    
    output_file = args.output or f"tieba_{args.forum}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    
    print(f"[*] 开始抓取贴吧: {args.forum}")
    print(f"[*] 抓取页数: {args.pages}")
    print()
    
    posts = scrape_tieba_forum(args.forum, args.pages)
    
    if posts:
        save_to_json(posts, output_file)
        
        if args.import_db:
            import_to_db(posts, args.forum)
        
        print(f"\n[完成] 共抓取 {len(posts)} 条帖子")
    else:
        print("\n[!] 未抓取到任何帖子")

if __name__ == '__main__':
    main()
