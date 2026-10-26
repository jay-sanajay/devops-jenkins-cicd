"""
Unit tests for Flask application using Pytest and Flask test client.
Executed automatically in Stage 3 ('Run Tests') of the Jenkins pipeline.
"""

import json
import pytest
from app import app


@pytest.fixture
def client():
    """
    Pytest fixture that creates a Flask test client.
    Enables sending HTTP requests to the app without starting a real network server.
    """
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_home_endpoint(client):
    """
    Test GET / endpoint:
    - Should return HTTP 200 OK.
    - Should return JSON payload with project name and online status.
    """
    response = client.get("/")
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data["project"] == "DevOps CI/CD Demo Application"
    assert data["status"] == "online"
    assert "endpoints" in data


def test_health_endpoint(client):
    """
    Test GET /health endpoint:
    - Should return HTTP 200 OK.
    - Should report status: 'healthy'.
    - Should include uptime and service name.
    """
    response = client.get("/health")
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data["status"] == "healthy"
    assert data["service"] == "devops-cicd-app"
    assert "uptime_seconds" in data
    assert data["uptime_seconds"] >= 0


def test_version_endpoint(client):
    """
    Test GET /version endpoint:
    - Should return HTTP 200 OK.
    - Should return expected semantic version (e.g., '1.0.0').
    - Should include python version and environment.
    """
    response = client.get("/version")
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data["version"] == "1.0.0"
    assert "environment" in data
    assert "python_version" in data


def test_not_found_endpoint(client):
    """
    Test invalid route handling (404 Not Found):
    - Should return HTTP 404 status code.
    - Should return structured JSON error object.
    """
    response = client.get("/nonexistent-endpoint")
    assert response.status_code == 404
    data = json.loads(response.data)
    assert data["error"] == "Not Found"
    assert data["status_code"] == 404


def test_method_not_allowed(client):
    """
    Test unsupported HTTP method (405 Method Not Allowed):
    - Sending POST to GET-only /health should fail with 405.
    """
    response = client.post("/health", data=json.dumps({"test": "data"}))
    assert response.status_code == 405
    data = json.loads(response.data)
    assert data["error"] == "Method Not Allowed"
    assert data["status_code"] == 405
