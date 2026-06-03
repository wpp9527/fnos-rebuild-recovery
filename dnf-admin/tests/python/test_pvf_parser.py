"""
Unit tests for PVF Parser Service
"""

import pytest
import sys
import os

# Add the pvf-service directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../pvf-service'))

from pvf_parser import PVFListParser, PVFBinaryParser, calculate_checksum, compare_versions


class TestPVFListParser:
    """Tests for PVFListParser"""

    def test_parse_line_valid(self):
        line = "12345\tTest Item\tDescription\tType1\t50\t1000"
        result = PVFListParser.parse_line(line)
        assert result is not None
        assert result['id'] == 12345
        assert result['name'] == 'Test Item'
        assert len(result['fields']) == 4

    def test_parse_line_empty(self):
        result = PVFListParser.parse_line("")
        assert result is None

    def test_parse_line_comment(self):
        result = PVFListParser.parse_line("# This is a comment")
        assert result is None

    def test_parse_line_invalid_id(self):
        result = PVFListParser.parse_line("not_a_number\tItem")
        assert result is None


class TestUtilityFunctions:
    """Tests for utility functions"""

    def test_calculate_checksum(self):
        data = b"test data"
        checksum = calculate_checksum(data)
        assert isinstance(checksum, int)
        assert checksum > 0

    def test_calculate_checksum_empty(self):
        checksum = calculate_checksum(b"")
        assert checksum == 0

    def test_compare_versions_equal(self):
        result = compare_versions("1.0.0", "1.0.0")
        assert result == 0

    def test_compare_versions_less(self):
        result = compare_versions("1.0.0", "1.0.1")
        assert result < 0

    def test_compare_versions_greater(self):
        result = compare_versions("1.0.1", "1.0.0")
        assert result > 0


class TestPVFFileReader:
    """Tests for PVFFileReader"""

    def test_read_nonexistent_file(self):
        from pvf_parser import PVFFileReader
        reader = PVFFileReader("/nonexistent/file.pvf")
        result = reader.read()
        assert result is False

    def test_read_string_empty_data(self):
        from pvf_parser import PVFFileReader
        reader = PVFFileReader("/nonexistent/file.pvf")
        result = reader.read_string(0)
        assert result == ""


class TestPVFBinaryParser:
    """Tests for PVFBinaryParser"""

    def test_parse_header_nonexistent_file(self):
        parser = PVFBinaryParser("/nonexistent/file.pvf")
        result = parser.parse_header()
        assert result is None
