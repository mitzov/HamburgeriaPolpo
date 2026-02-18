#!/usr/bin/env bash
# Script per avviare SOLO il backend (utile per debugging)

cd "$(dirname "$0")/backend"
python -m venv .venv 2>/dev/null || true
. .venv/bin/activate
pip install -r requirements.txt
python app.py
