# tests/test_openapi.py
import importlib
import os

import pytest
from fastapi.testclient import TestClient


@pytest.fixture(scope="session")
def app():
    import_path = os.getenv("APP_IMPORT_PATH", "app.main:app")
    module_path, app_name = import_path.split(":")
    module = importlib.import_module(module_path)
    return getattr(module, app_name)


@pytest.fixture(scope="session")
def client(app):
    return TestClient(app)


def test_openapi_available(client):
    # OpenAPI JSON should be present and parseable
    resp = client.get("/openapi.json")
    assert resp.status_code == 200, "OpenAPI (openapi.json) must be served for DAST"
    assert "openapi" in resp.json(), "Invalid OpenAPI response"


def test_swagger_ui(client):
    # docs page should exist (html)
    resp = client.get("/docs")
    assert resp.status_code == 200
    assert "<title>" in resp.text.lower()
