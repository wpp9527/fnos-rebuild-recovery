"""
Unit tests for PVF Flask App
"""

import pytest
import sys
import os

# Add the pvf-service directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../pvf-service'))

from app import app


@pytest.fixture
def client():
    """Create a test client"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


class TestHealthEndpoint:
    """Tests for health check endpoint"""

    def test_health_check(self, client):
        response = client.get('/health')
        assert response.status_code == 200
        data = response.get_json()
        assert data['status'] == 'ok'


class TestItemEndpoints:
    """Tests for item endpoints"""

    def test_search_items_empty_query(self, client):
        response = client.get('/api/items')
        assert response.status_code == 200
        data = response.get_json()
        assert isinstance(data, list)

    def test_search_items_with_query(self, client):
        response = client.get('/api/items?q=test')
        assert response.status_code == 200
        data = response.get_json()
        assert isinstance(data, list)

    def test_get_item_not_found(self, client):
        response = client.get('/api/items/999999')
        assert response.status_code == 404


class TestEquipmentEndpoints:
    """Tests for equipment endpoints"""

    def test_search_equipments_empty_query(self, client):
        response = client.get('/api/equipments')
        assert response.status_code == 200
        data = response.get_json()
        assert isinstance(data, list)

    def test_search_equipments_with_query(self, client):
        response = client.get('/api/equipments?q=sword')
        assert response.status_code == 200


class TestSkillEndpoints:
    """Tests for skill endpoints"""

    def test_search_skills_empty_query(self, client):
        response = client.get('/api/skills')
        assert response.status_code == 200
        data = response.get_json()
        assert isinstance(data, list)


class TestStatsEndpoint:
    """Tests for stats endpoint"""

    def test_get_stats(self, client):
        response = client.get('/api/stats')
        assert response.status_code == 200
        data = response.get_json()
        assert 'total_items' in data
        assert 'total_equipments' in data
        assert 'total_skills' in data


class TestReloadEndpoint:
    """Tests for reload endpoint"""

    def test_reload_pvf(self, client):
        response = client.post('/api/reload')
        assert response.status_code == 200
        data = response.get_json()
        assert 'message' in data
