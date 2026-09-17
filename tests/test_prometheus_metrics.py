"""
Test Prometheus Metrics Integration

Verifies that metrics are being collected and exposed correctly.
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

import pytest
from fastapi.testclient import TestClient
from tiannara_api.main import app


@pytest.fixture
def client():
    """Create test client."""
    return TestClient(app)


def test_metrics_endpoint_exists(client):
    """Test that /metrics endpoint exists and returns data."""
    response = client.get("/metrics")
    
    assert response.status_code == 200
    assert "text/plain" in response.headers["content-type"]
    
    # Check for basic metrics
    content = response.text
    assert "http_requests_total" in content or "# HELP" in content


def test_health_endpoint(client):
    """Test health check endpoint."""
    response = client.get("/health")
    
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "version" in data


def test_metrics_collect_request_data(client):
    """Test that requests are being tracked."""
    # Make a request
    response = client.get("/health")
    assert response.status_code == 200
    
    # Check metrics
    metrics_response = client.get("/metrics")
    assert metrics_response.status_code == 200
    
    # Should contain HTTP metrics
    content = metrics_response.text
    assert "http_request" in content.lower()


def test_system_metrics_present(client):
    """Test that system metrics are collected."""
    response = client.get("/metrics")
    assert response.status_code == 200
    
    content = response.text
    
    # Check for system metrics
    assert any(metric in content for metric in [
        "system_cpu_usage",
        "system_memory_usage",
        "process_uptime"
    ])


if __name__ == "__main__":
    # Run tests
    pytest.main([__file__, "-v"])
