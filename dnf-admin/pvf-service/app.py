"""
DNF PVF Parser Service
Based on Zageku/DNF_pvf_python
Provides REST API for parsing DNF PVF files
"""

import os
import sys
import json
import struct
import hashlib
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from functools import lru_cache

from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Global PVF data store
pvf_data = {
    "items": {},
    "equipments": {},
    "skills": {},
    "loaded": False,
    "last_updated": None
}


@dataclass
class PVFItem:
    """Represents a PVF item"""
    id: int
    name: str
    description: str
    type: str
    rarity: int
    price: int
    stackable: bool
    tradeable: bool

    def to_dict(self):
        return asdict(self)


@dataclass
class PVFEquipment:
    """Represents a PVF equipment"""
    id: int
    name: str
    description: str
    type: str
    level: int
    job: int
    stats: Dict[str, int]
    rarity: int
    price: int

    def to_dict(self):
        return asdict(self)


@dataclass
class PVFSkill:
    """Represents a PVF skill"""
    id: int
    name: str
    description: str
    level: int
    job: int
    max_level: int
    cooldown: float

    def to_dict(self):
        return asdict(self)


class PVFParser:
    """Main PVF parser class"""

    def __init__(self, pvf_path: str = "/root/.openclaw/workspace/dnf-admin/data/pvf"):
        self.pvf_path = Path(pvf_path)
        self.items: Dict[int, PVFItem] = {}
        self.equipments: Dict[int, PVFEquipment] = {}
        self.skills: Dict[int, PVFSkill] = {}

    def load_all(self) -> bool:
        """Load all PVF data"""
        try:
            self.load_items()
            self.load_equipments()
            self.load_skills()
            return True
        except Exception as e:
            print(f"Error loading PVF: {e}")
            return False

    def load_items(self):
        """Load items from PVF files"""
        item_file = self.pvf_path / "item.lst"
        if not item_file.exists():
            print(f"Item file not found: {item_file}")
            return

        with open(item_file, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                parts = line.split(',')
                if len(parts) >= 6:
                    try:
                        item_id = int(parts[0])
                        item = PVFItem(
                            id=item_id,
                            name=parts[1],
                            description=parts[2] if len(parts) > 2 else "",
                            type=parts[3] if len(parts) > 3 else "unknown",
                            rarity=int(parts[4]) if len(parts) > 4 else 0,
                            price=int(parts[5]) if len(parts) > 5 else 0,
                            stackable=True,
                            tradeable=True
                        )
                        self.items[item_id] = item
                    except (ValueError, IndexError):
                        continue

    def load_equipments(self):
        """Load equipments from PVF files"""
        equip_file = self.pvf_path / "equipment.lst"
        if not equip_file.exists():
            print(f"Equipment file not found: {equip_file}")
            return

        with open(equip_file, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                parts = line.split(',')
                if len(parts) >= 7:
                    try:
                        equip_id = int(parts[0])
                        stats = {}
                        if len(parts) > 7:
                            for stat_str in parts[7].split(','):
                                if ':' in stat_str:
                                    k, v = stat_str.split(':')
                                    stats[k.strip()] = int(v.strip())

                        equip = PVFEquipment(
                            id=equip_id,
                            name=parts[1],
                            description=parts[2] if len(parts) > 2 else "",
                            type=parts[3] if len(parts) > 3 else "unknown",
                            level=int(parts[4]) if len(parts) > 4 else 1,
                            job=int(parts[5]) if len(parts) > 5 else 0,
                            stats=stats,
                            rarity=int(parts[6]) if len(parts) > 6 else 0,
                            price=int(parts[7]) if len(parts) > 7 else 0
                        )
                        self.equipments[equip_id] = equip
                    except (ValueError, IndexError):
                        continue

    def load_skills(self):
        """Load skills from PVF files"""
        skill_file = self.pvf_path / "skill.lst"
        if not skill_file.exists():
            print(f"Skill file not found: {skill_file}")
            return

        with open(skill_file, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                parts = line.split(',')
                if len(parts) >= 6:
                    try:
                        skill_id = int(parts[0])
                        skill = PVFSkill(
                            id=skill_id,
                            name=parts[1],
                            description=parts[2] if len(parts) > 2 else "",
                            level=int(parts[3]) if len(parts) > 3 else 1,
                            job=int(parts[4]) if len(parts) > 4 else 0,
                            max_level=int(parts[5]) if len(parts) > 5 else 10,
                            cooldown=float(parts[6]) if len(parts) > 6 else 0.0
                        )
                        self.skills[skill_id] = skill
                    except (ValueError, IndexError):
                        continue

    def search_items(self, query: str) -> List[Dict]:
        """Search items by name or ID"""
        results = []
        query_lower = query.lower()
        for item in self.items.values():
            name_match = query_lower in item.name.lower()
            desc_match = query_lower in item.description.lower()
            id_match = query.isdigit() and item.id == int(query)
            if name_match or desc_match or id_match:
                results.append(item.to_dict())
        return results

    def search_equipments(self, query: str) -> List[Dict]:
        """Search equipments by name or ID"""
        results = []
        query_lower = query.lower()
        for equip in self.equipments.values():
            if (query_lower in equip.name.lower() or
                query_lower in equip.description.lower() or
                query.isdigit() and equip.id == int(query)):
                results.append(equip.to_dict())
        return results

    def search_skills(self, query: str) -> List[Dict]:
        """Search skills by name or ID"""
        results = []
        query_lower = query.lower()
        for skill in self.skills.values():
            if (query_lower in skill.name.lower() or
                query_lower in skill.description.lower() or
                query.isdigit() and skill.id == int(query)):
                results.append(skill.to_dict())
        return results

    def get_stats(self) -> Dict:
        """Get PVF statistics"""
        return {
            "total_items": len(self.items),
            "total_equipments": len(self.equipments),
            "total_skills": len(self.skills),
            "last_updated": pvf_data.get("last_updated", "never")
        }


# Global parser instance
parser = PVFParser()


@app.route('/api/items', methods=['GET'])
def search_items():
    """Search items"""
    query = request.args.get('q', '')
    if not query:
        return jsonify([])
    results = parser.search_items(query)
    return jsonify(results)


@app.route('/api/items/<int:item_id>', methods=['GET'])
def get_item(item_id):
    """Get item by ID"""
    if item_id in parser.items:
        return jsonify(parser.items[item_id].to_dict())
    return jsonify({"error": "item not found"}), 404


@app.route('/api/equipments', methods=['GET'])
def search_equipments():
    """Search equipments"""
    query = request.args.get('q', '')
    if not query:
        return jsonify([])
    results = parser.search_equipments(query)
    return jsonify(results)


@app.route('/api/skills', methods=['GET'])
def search_skills():
    """Search skills"""
    query = request.args.get('q', '')
    if not query:
        return jsonify([])
    results = parser.search_skills(query)
    return jsonify(results)


@app.route('/api/stats', methods=['GET'])
def get_stats():
    """Get PVF statistics"""
    return jsonify(parser.get_stats())


@app.route('/api/reload', methods=['POST'])
def reload_pvf():
    """Reload PVF data"""
    global pvf_data
    success = parser.load_all()
    if success:
        from datetime import datetime
        pvf_data["last_updated"] = datetime.now().isoformat()
        return jsonify({"message": "PVF reloaded successfully"})
    return jsonify({"error": "Failed to reload PVF"}), 500


@app.route('/health', methods=['GET'])
def health():
    """Health check"""
    return jsonify({"status": "ok"})


if __name__ == '__main__':
    # Load PVF data on startup
    print("Loading PVF data...")
    parser.load_all()
    print(f"Loaded: {len(parser.items)} items, {len(parser.equipments)} equipments, {len(parser.skills)} skills")

    # Start Flask server
    app.run(host='0.0.0.0', port=5000, debug=False)
