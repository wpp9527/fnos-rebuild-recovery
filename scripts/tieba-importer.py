#!/usr/bin/env python3
"""
贴吧帖子导入器 - 将抓取的帖子导入到 DNF 数据库
用法: python3 tieba-importer.py /tmp/tieba_test.json
"""
import json
import sys
import pymysql
from datetime import datetime

DB_CONFIG = {
    'host': '172.18.0.2',
    'port': 3306,
    'user': 'root',
    'password': '88888888',
    'database': 'dnf_tieba',
    'charset': 'utf8mb4',
}

def import_posts(posts):
    """导入帖子到数据库"""
    conn = pymysql.connect(**DB_CONFIG)
    cursor = conn.cursor()
    
    # 创建表（如果不存在）
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS tieba_posts (
            id BIGINT AUTO_INCREMENT PRIMARY KEY,
            tid VARCHAR(20) NOT NULL UNIQUE,
            title VARCHAR(500) NOT NULL,
            author VARCHAR(100) DEFAULT '',
            reply_num INT DEFAULT 0,
            view_num INT DEFAULT 0,
            last_time VARCHAR(50) DEFAULT '',
            abstract TEXT,
            scraped_at DATETIME,
            imported_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_tid (tid),
            INDEX idx_title (title(100))
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    """)
    
    imported = 0
    skipped = 0
    
    for post in posts:
        try:
            cursor.execute("""
                INSERT INTO tieba_posts (tid, title, author, reply_num, view_num, last_time, abstract, scraped_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                ON DUPLICATE KEY UPDATE
                    title = VALUES(title),
                    reply_num = VALUES(reply_num),
                    view_num = VALUES(view_num),
                    last_time = VALUES(last_time),
                    abstract = VALUES(abstract),
                    scraped_at = VALUES(scraped_at)
            """, (
                post['tid'],
                post['title'],
                post.get('author', ''),
                post.get('reply_num', 0),
                post.get('view_num', 0),
                post.get('last_time', ''),
                post.get('abstract', ''),
                post.get('scraped_at', datetime.now().isoformat()),
            ))
            imported += 1
        except pymysql.err.IntegrityError:
            skipped += 1
        except Exception as e:
            print(f"  [ERR] {post['title'][:30]}: {e}")
    
    conn.commit()
    cursor.close()
    conn.close()
    
    return imported, skipped

def main():
    if len(sys.argv) < 2:
        print("用法: python3 tieba-importer.py <json_file>")
        sys.exit(1)
    
    json_file = sys.argv[1]
    
    with open(json_file, 'r', encoding='utf-8') as f:
        posts = json.load(f)
    
    print(f"[*] 加载 {len(posts)} 条帖子")
    print(f"[*] 开始导入到数据库...")
    
    imported, skipped = import_posts(posts)
    
    print(f"\n[完成] 导入 {imported} 条，跳过 {skipped} 条")

if __name__ == '__main__':
    main()
