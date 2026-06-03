"""
DNF PVF Parser Module
Provides parsing logic for DNF PVF files
"""

import os
import struct
from pathlib import Path
from typing import Dict, List, Optional, BinaryIO
from dataclasses import dataclass


@dataclass
class PVFItemData:
    """Raw item data from PVF"""
    id: int
    name: str
    description: str
    item_type: int
    rarity: int
    price: int
    weight: float
    stackable: bool
    tradeable: bool
    droppable: bool


@dataclass
class PVFEquipmentData:
    """Raw equipment data from PVF"""
    id: int
    name: str
    description: str
    equip_type: int
    level: int
    job: int
    rarity: int
    price: int
    durability: int
    stats: Dict[str, int]


class PVFFileReader:
    """Reads and parses PVF binary files"""

    def __init__(self, filepath: str):
        self.filepath = Path(filepath)
        self.data: Optional[bytes] = None

    def read(self) -> bool:
        """Read the PVF file"""
        try:
            with open(self.filepath, 'rb') as f:
                self.data = f.read()
            return True
        except Exception as e:
            print(f"Error reading PVF file: {e}")
            return False

    def read_uint32(self, offset: int) -> int:
        """Read a 32-bit unsigned integer"""
        if self.data is None or offset + 4 > len(self.data):
            return 0
        return struct.unpack('<I', self.data[offset:offset + 4])[0]

    def read_uint16(self, offset: int) -> int:
        """Read a 16-bit unsigned integer"""
        if self.data is None or offset + 2 > len(self.data):
            return 0
        return struct.unpack('<H', self.data[offset:offset + 2])[0]

    def read_string(self, offset: int, encoding: str = 'cp949') -> str:
        """Read a null-terminated string"""
        if self.data is None:
            return ""

        end = self.data.find(b'\x00', offset)
        if end == -1:
            end = len(self.data)

        try:
            return self.data[offset:end].decode(encoding, errors='ignore')
        except Exception:
            return ""

    def read_wide_string(self, offset: int) -> str:
        """Read a null-terminated wide string"""
        if self.data is None:
            return ""

        end = offset
        while end + 1 < len(self.data):
            if self.data[end] == 0 and self.data[end + 1] == 0:
                break
            end += 2

        try:
            return self.data[offset:end].decode('utf-16-le', errors='ignore')
        except Exception:
            return ""


class PVFListParser:
    """Parse .lst (list) format PVF files"""

    @staticmethod
    def parse_line(line: str) -> Optional[Dict]:
        """Parse a single line from a .lst file"""
        line = line.strip()
        if not line or line.startswith('#'):
            return None

        parts = line.split('\t')
        if len(parts) < 2:
            return None

        try:
            return {
                'id': int(parts[0]),
                'name': parts[1] if len(parts) > 1 else '',
                'fields': parts[2:] if len(parts) > 2 else []
            }
        except ValueError:
            return None

    @staticmethod
    def parse_file(filepath: str) -> List[Dict]:
        """Parse a .lst file"""
        results = []
        try:
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                for line in f:
                    parsed = PVFListParser.parse_line(line)
                    if parsed:
                        results.append(parsed)
        except Exception as e:
            print(f"Error parsing {filepath}: {e}")
        return results


class PVFBinaryParser:
    """Parse binary PVF format files"""

    HEADER_SIZE = 32
    MAGIC_NUMBER = 0x50564600  # "PVF\0"

    def __init__(self, filepath: str):
        self.reader = PVFFileReader(filepath)

    def parse_header(self) -> Optional[Dict]:
        """Parse the PVF file header"""
        if not self.reader.read():
            return None

        magic = self.reader.read_uint32(0)
        if magic != self.MAGIC_NUMBER:
            print(f"Invalid magic number: {hex(magic)}")
            return None

        version = self.reader.read_uint32(4)
        item_count = self.reader.read_uint32(8)
        equip_count = self.reader.read_uint32(12)
        skill_count = self.reader.read_uint32(16)

        return {
            'magic': magic,
            'version': version,
            'item_count': item_count,
            'equip_count': equip_count,
            'skill_count': skill_count
        }

    def parse_items(self, count: int) -> List[PVFItemData]:
        """Parse item entries"""
        items = []
        offset = self.HEADER_SIZE

        for _ in range(count):
            if offset + 64 > len(self.reader.data or b''):
                break

            item_id = self.reader.read_uint32(offset)
            name = self.reader.read_string(offset + 4)
            description = self.reader.read_string(offset + 128)
            item_type = self.reader.read_uint16(offset + 256)
            rarity = self.reader.read_uint16(offset + 258)
            price = self.reader.read_uint32(offset + 260)

            item = PVFItemData(
                id=item_id,
                name=name,
                description=description,
                item_type=item_type,
                rarity=rarity,
                price=price,
                weight=0.0,
                stackable=True,
                tradeable=True,
                droppable=True
            )
            items.append(item)
            offset += 512  # Fixed size per item

        return items


# Utility functions for PVF operations

def calculate_checksum(data: bytes) -> int:
    """Calculate simple checksum for data integrity"""
    return sum(data) & 0xFFFFFFFF


def compare_versions(v1: str, v2: str) -> int:
    """Compare two version strings"""
    parts1 = [int(x) for x in v1.split('.')]
    parts2 = [int(x) for x in v2.split('.')]

    for p1, p2 in zip(parts1, parts2):
        if p1 < p2:
            return -1
        if p1 > p2:
            return 1

    return len(parts1) - len(parts2)


def extract_item_id_from_name(name: str) -> Optional[int]:
    """Try to extract item ID from name if it follows naming convention"""
    # Some PVF files use naming like "item_12345"
    parts = name.split('_')
    if len(parts) > 1:
        try:
            return int(parts[-1])
        except ValueError:
            pass
    return None
