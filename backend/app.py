from flask import Flask, jsonify, request, abort
from flask_cors import CORS
import os
from database_wrapper import DatabaseWrapper

# ─────────────────────────── Config ───────────────────────────────
app = Flask(__name__)
CORS(app)  # permetti cross-origin per Flutter web e Angular

db = DatabaseWrapper(
    host     = os.getenv("DB_HOST",     "mysql-hamburger.aivencloud.com"),
    port     = int(os.getenv("DB_PORT", "3306")),
    user     = os.getenv("DB_USER",     "avnadmin"),
    password = os.getenv("DB_PASSWORD", "AVNS_your_password_here"),
    db       = os.getenv("DB_NAME",     "hamburger_db"),
)


# ─────────────────────────── Helpers ──────────────────────────────
def ok(data=None, msg: str = "OK", code: int = 200):
    body = {"success": True, "message": msg}
    if data is not None:
        body["data"] = data
    return jsonify(body), code


def err(msg: str, code: int = 400):
    return jsonify({"success": False, "message": msg}), code


# ─────────────────────────── Health ───────────────────────────────
@app.route("/api/health", methods=["GET"])
def health():
    return ok(msg="HamBurger backend operativo 🍔")


# ─────────────────────────── SETUP ────────────────────────────────
@app.route("/api/setup", methods=["POST"])
def setup():
    """Inizializza schema DB e dati seed. Da chiamare una sola volta."""
    db.init_schema()
    return ok(msg="Schema e dati inizializzati correttamente")


# ─────────────────────────── MENU (pubblico) ──────────────────────
@app.route("/api/menu", methods=["GET"])
def get_menu():
    """Ritorna tutto il menu raggruppato per categoria."""
    menu = db.get_menu()
    # converti Decimal → float per JSON
    for cat in menu:
        for p in cat["prodotti"]:
            p["prezzo"] = float(p["prezzo"])
    return ok(menu)


# ─────────────────────────── CATEGORIE ────────────────────────────
@app.route("/api/categorie", methods=["GET"])
def get_categorie():
    return ok(db.get_categorie())


@app.route("/api/categorie", methods=["POST"])
def add_categoria():
    body = request.get_json(silent=True) or {}
    nome = (body.get("nome") or "").strip()
    if not nome:
        return err("Il campo 'nome' è obbligatorio")
    try:
        cat_id = db.add_categoria(nome)
        return ok({"id": cat_id, "nome": nome}, "Categoria creata", 201)
    except Exception as e:
        return err(str(e))


# ─────────────────────────── PRODOTTI ─────────────────────────────
@app.route("/api/prodotti", methods=["GET"])
def get_prodotti():
    prodotti = db.get_prodotti()
    for p in prodotti:
        p["prezzo"] = float(p["prezzo"])
    return ok(prodotti)


@app.route("/api/prodotti/<int:pid>", methods=["GET"])
def get_prodotto(pid: int):
    p = db.get_prodotto(pid)
    if not p:
        return err("Prodotto non trovato", 404)
    p["prezzo"] = float(p["prezzo"])
    return ok(p)


@app.route("/api/prodotti", methods=["POST"])
def add_prodotto():
    body = request.get_json(silent=True) or {}
    required = ("categoria_id", "nome", "prezzo")
    missing = [f for f in required if not body.get(f)]
    if missing:
        return err(f"Campi obbligatori mancanti: {', '.join(missing)}")
    try:
        pid = db.add_prodotto(
            categoria_id = int(body["categoria_id"]),
            nome         = body["nome"].strip(),
            descrizione  = (body.get("descrizione") or "").strip(),
            prezzo       = float(body["prezzo"]),
            immagine     = body.get("immagine"),
        )
        prodotto = db.get_prodotto(pid)
        prodotto["prezzo"] = float(prodotto["prezzo"])
        return ok(prodotto, "Prodotto creato", 201)
    except Exception as e:
        return err(str(e))


@app.route("/api/prodotti/<int:pid>", methods=["PUT"])
def update_prodotto(pid: int):
    body = request.get_json(silent=True) or {}
    fields = {}
    if "categoria_id"  in body: fields["categoria_id"]  = int(body["categoria_id"])
    if "nome"          in body: fields["nome"]           = body["nome"].strip()
    if "descrizione"   in body: fields["descrizione"]    = body["descrizione"]
    if "prezzo"        in body: fields["prezzo"]         = float(body["prezzo"])
    if "immagine"      in body: fields["immagine"]       = body["immagine"]
    if "disponibile"   in body: fields["disponibile"]    = int(bool(body["disponibile"]))
    if not fields:
        return err("Nessun campo da aggiornare")
    updated = db.update_prodotto(pid, **fields)
    if not updated:
        return err("Prodotto non trovato", 404)
    prodotto = db.get_prodotto(pid)
    prodotto["prezzo"] = float(prodotto["prezzo"])
    return ok(prodotto, "Prodotto aggiornato")


@app.route("/api/prodotti/<int:pid>", methods=["DELETE"])
def delete_prodotto(pid: int):
    deleted = db.delete_prodotto(pid)
    if not deleted:
        return err("Prodotto non trovato", 404)
    return ok(msg="Prodotto eliminato")


# ─────────────────────────── ORDINI ───────────────────────────────
@app.route("/api/ordini", methods=["GET"])
def get_ordini():
    stato = request.args.get("stato")
    ordini = db.get_ordini(stato)
    for o in ordini:
        o["totale"] = float(o["totale"])
        for r in o["righe"]:
            r["prezzo_unit"] = float(r["prezzo_unit"])
    return ok(ordini)


@app.route("/api/ordini/<int:oid>", methods=["GET"])
def get_ordine(oid: int):
    o = db.get_ordine(oid)
    if not o:
        return err("Ordine non trovato", 404)
    o["totale"] = float(o["totale"])
    for r in o["righe"]:
        r["prezzo_unit"] = float(r["prezzo_unit"])
    return ok(o)


@app.route("/api/ordini", methods=["POST"])
def crea_ordine():
    body = request.get_json(silent=True) or {}
    righe = body.get("righe", [])
    if not righe:
        return err("Il carrello è vuoto")
    try:
        result = db.crea_ordine(righe, body.get("note", ""))
        result["totale"] = float(result["totale"])
        return ok(result, "Ordine inviato in cucina! 🍔", 201)
    except ValueError as e:
        return err(str(e))
    except Exception as e:
        return err(f"Errore interno: {e}", 500)


@app.route("/api/ordini/<int:oid>/stato", methods=["PATCH"])
def update_stato_ordine(oid: int):
    body = request.get_json(silent=True) or {}
    stato = (body.get("stato") or "").strip()
    if not stato:
        return err("Il campo 'stato' è obbligatorio")
    try:
        updated = db.update_stato_ordine(oid, stato)
        if not updated:
            return err("Ordine non trovato", 404)
        return ok(msg=f"Stato aggiornato a '{stato}'")
    except ValueError as e:
        return err(str(e))


# ─────────────────────────── STATS ────────────────────────────────
@app.route("/api/stats", methods=["GET"])
def get_stats():
    stats = db.get_stats()
    stats["incasso"] = float(stats["incasso"] or 0)
    return ok(stats)


# ─────────────────────────── Main ─────────────────────────────────
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)