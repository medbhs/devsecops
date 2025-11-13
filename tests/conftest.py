"""
Auto-discovers your FastAPI app for tests.

Default: import app.main:app
Override: set env APP_IMPORT_PATH="your.module.path:appobj"
"""

import os
import importlib
import pytest
from fastapi.testclient import TestClient  # FastAPI exposes Starlette's TestClient


@pytest.fixture(scope="session")
def app():
    import_path = os.getenv("APP_IMPORT_PATH", "app.main:app")
    module_path, app_name = import_path.split(":")
    module = importlib.import_module(module_path)
    return getattr(module, app_name)


@pytest.fixture(scope="session")
def client(app):
    return TestClient(app)
