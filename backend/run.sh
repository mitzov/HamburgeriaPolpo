#!/usr/bin/env bash
set -euo pipefail

# Esempio di avvio backend con variabili d'ambiente (Aiven MySQL)
# Esportare le variabili reali fornite da Aiven oppure lasciare vuote per usare SQLite di fallback.
# DB_SSL_CA_B64 può contenere il certificato CA in base64 (se non volete creare file separato).

export DB_HOST="${DB_HOST:-mysql-3f12020f-galvani5d.j.aivencloud.com}"
export DB_USER="${DB_USER:-avnadmin}"
export DB_PASSWORD="${DB_PASSWORD:-AVNS_idAGBvmY7bsHyDkUXBM}"
export DB_NAME="${DB_NAME:-defaultdb}"
export DB_PORT="${DB_PORT:-13861}"

echo "Avvio backend (Flask). Se DB_HOST è configurato cerco di connettermi a MySQL, altrimenti uso SQLite locale."
python -m venv .venv || true
. .venv/bin/activate
pip install -r requirements.txt
python app.py
