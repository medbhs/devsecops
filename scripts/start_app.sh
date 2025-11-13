#!/usr/bin/env bash
set -euo pipefail
APP_IMPORT_PATH="${APP_IMPORT_PATH:-app.main:app}"
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8000}"
python - <<'PY'
import importlib, os
mod, obj = os.environ.get("APP_IMPORT_PATH","app.main:app").split(":")
app = getattr(importlib.import_module(mod), obj)
from uvicorn import run
run(app=app, host=os.environ.get("HOST","0.0.0.0"), port=int(os.environ.get("PORT","8000")))
