#!/usr/bin/env bash
cd /workspaces/HamburgeriaPolpo/backend
python -m venv .venv 2>/dev/null || true
. .venv/bin/activate
pip install -r requirements.txt -q
echo "Backend in avvio..."
python app.py
