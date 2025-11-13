import os
import sys
import importlib
import pytest
from fastapi.testclient import TestClient

# Ensure the root directory is in the Python path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))


@pytest.fixture(scope="session")
def app():
    """
    Import the FastAPI app dynamically based on APP_IMPORT_PATH
    or default to app.main:app
    """
    import_path = os.getenv("APP_IMPORT_PATH", "app.main:app")
    module_path, app_name = import_path.split(":")
    module = importlib.import_module(module_path)
    return getattr(module, app_name)


@pytest.fixture()
def client(app):
    """
    Return a TestClient instance for the FastAPI app.
    Used by endpoint/security tests.
    """
    return TestClient(app)
