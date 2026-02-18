# HamburgeriaPolpo

Progetto per l'esercitazione "Hamburgeria" — Totem cliente (Flutter), Pannello staff (Angular) e Backend (Flask + MySQL).

Prerequisiti generali
- Docker / devcontainer con Flutter + Node + Python (fornito nella consegna)
- Python 3.10+, Flutter, Node 18+, npm

Avvio rapido (locale)

1) Backend (Flask)

```bash
cd backend
# creare e attivare virtualenv (opzionale ma raccomandato)
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
# Inserire le credenziali Aiven in backend/database_wrapper.py (host, password, port)
python app.py
```

Il backend espone le seguenti rotte utili:
- `GET /menu` — ottiene la lista dei prodotti
- `POST /menu` — aggiunge un prodotto (body JSON: `name`, `price`, `category`)
- `GET /orders` — lista ordini
- `POST /orders` — crea un ordine (body JSON: `items`, `total_price`)
- `PATCH /orders/<id>` — aggiorna lo stato (body JSON: `status`)

2) Pannello staff (Angular)

```bash
cd HamburgeriaPolpo
npm install
npx ng serve --open --host 0.0.0.0 --port 4200
```

Il codice principale del pannello staff è in `HamburgeriaPolpo/src/app`.

3) Totem cliente (Flutter)

```bash
cd totem_flutter
flutter pub get
flutter run -d <device>
```

Avvio Completo (Scelta Consigliata)

Usa lo script automatico dalla root del workspace:

```bash
chmod +x START.sh
./START.sh
```

Questo avvia:
- Backend Flask su http://127.0.0.1:5000
- Frontend Angular su http://127.0.0.1:4200
- Mostra PID e log di entrambi

Per fermare: `kill <PID_BACKEND> <PID_ANGULAR>`

Note utili
- Il backend userà automaticamente SQLite locale se MySQL non è configurato (fallback sicuro).
- Le credenziali Aiven sono in `backend/database_wrapper.py` tramite variabili d'ambiente.
- Se cambi credenziali Aiven, usa `export DB_HOST=...` e riavvia il backend.
- Tutti gli endpoint supportano parametri sia in inglese che italiano (es. `name` e `nome`).

Struttura del Progetto

```
/backend                   # Flask API + DatabaseWrapper
  ├── app.py
  ├── database_wrapper.py   # MySQL + SQLite fallback
  ├── requirements.txt
  └── run.sh

/HamburgeriaPolpo          # Angular Staff Panel
  ├── src/app/
  │   ├── app.ts          # Componente principale
  │   └── app.html        # Template
  └── package.json

/totem_flutter             # Flutter Totem Cliente
  ├── lib/main.dart
  └── pubspec.yaml

START.sh                   # Script di avvio completo (CONSIGLIATO)
RUN_BACKEND_ONLY.sh        # Script per avviare solo il backend
README.md                  # Questo file
```

Contatti
- Repo: questa workspace contiene tutti i tre componenti richiesti per l'esame (Flutter, Angular, Flask).
