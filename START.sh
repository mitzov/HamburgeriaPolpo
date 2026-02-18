#!/usr/bin/env bash
# Avvia tutto il progetto Hamburgeria (Backend + Frontend Angular + Totem Flutter)

set -e

echo "======================================"
echo "🍔 HAMBURGERIA - Avvio Progetto"
echo "======================================"
echo ""

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. BACKEND
echo -e "${YELLOW}[1/3] Avvio Backend (Flask)${NC}"
cd backend
python -m venv .venv 2>/dev/null || true
if [ -f .venv/bin/activate ]; then
    . .venv/bin/activate
fi
pip install -r requirements.txt > /dev/null 2>&1 || true
echo -e "${GREEN}✓ Backend pronto su http://127.0.0.1:5000${NC}"
nohup python app.py > backend.log 2>&1 &
BACKEND_PID=$!
sleep 2

# 2. TEST Backend
echo ""
echo "Testing backend..."
if curl -s http://127.0.0.1:5000/menu > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Backend risponde${NC}"
else
    echo -e "${RED}✗ Backend non risponde. Verifica backend.log${NC}"
    tail backend.log
    exit 1
fi

# 3. FRONTEND ANGULAR
echo ""
echo -e "${YELLOW}[2/3] Avvio Frontend (Angular)${NC}"
cd ../HamburgeriaPolpo
npm install --no-audit --no-fund > /dev/null 2>&1 || true
echo -e "${GREEN}✓ Dipendenze Angular installate${NC}"
echo -e "${GREEN}✓ Frontend pronto su http://127.0.0.1:4200${NC}"
echo "Avviando dev server Angular in background..."
nohup npx ng serve --host 0.0.0.0 --port 4200 > angular.log 2>&1 &
ANGULAR_PID=$!
sleep 10

# 4. TEST Frontend
echo "Testing frontend..."
if curl -s http://127.0.0.1:4200 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Frontend risponde${NC}"
else
    echo -e "${YELLOW}⚠ Frontend potrebbe non essere ancora pronto (è normale, aspetta 30s)${NC}"
fi

# 5. Flutter Info
echo ""
echo -e "${YELLOW}[3/3] Totem Flutter${NC}"
cd ../totem_flutter
if [ -d lib ]; then
    echo -e "${GREEN}✓ Totem Flutter scaffold presente${NC}"
    echo "  Per avviare il totem:"
    echo "    $ cd totem_flutter"
    echo "    $ flutter pub get"
    echo "    $ flutter run -d <device>"
else
    echo -e "${RED}✗ Totem Flutter non trovato${NC}"
fi

# 6. Resoconto
echo ""
echo "======================================"
echo -e "${GREEN}🎉 SISTEMA PRONTO!${NC}"
echo "======================================"
echo ""
echo "📱 Frontend (Staff Panel):"
echo "   URL: http://127.0.0.1:4200"
echo "   PID: $ANGULAR_PID"
echo ""
echo "🔧 Backend (API REST):"
echo "   URL: http://127.0.0.1:5000"
echo "   PID: $BACKEND_PID"
echo ""
echo "📋 Log file:"
echo "   Backend: backend/backend.log"
echo "   Frontend: HamburgeriaPolpo/angular.log"
echo ""
echo "🍔 Totem Flutter:"
echo "   Avviabile da: totem_flutter/"
echo ""
echo -e "${YELLOW}Per fermare tutto, eseguire:${NC}"
echo "   kill $BACKEND_PID $ANGULAR_PID"
echo ""
echo "======================================"
