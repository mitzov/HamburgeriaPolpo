<<<<<<< HEAD
import pymysql
import pymysql.cursors
from contextlib import contextmanager


class DatabaseWrapper:
    """
    Centralizza tutte le query SQL.
    app.py chiama solo i metodi pubblici di questa classe.
    """

    def __init__(self, host: str, port: int, user: str, password: str, db: str):
        self._config = dict(
            host=host,
            port=port,
            user=user,
            password=password,
            database=db,
            charset="utf8mb4",
            cursorclass=pymysql.cursors.DictCursor,
            autocommit=False,
        )

    @contextmanager
    def _get_conn(self):
        conn = pymysql.connect(**self._config)
        try:
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    # ─────────────────────────── SETUP ────────────────────────────

    def init_schema(self):
        """Crea le tabelle se non esistono e inserisce dati di esempio."""
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS categorie (
                        id   INT AUTO_INCREMENT PRIMARY KEY,
                        nome VARCHAR(80) NOT NULL UNIQUE
                    ) ENGINE=InnoDB;
                """)
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS prodotti (
                        id          INT AUTO_INCREMENT PRIMARY KEY,
                        categoria_id INT NOT NULL,
                        nome        VARCHAR(120) NOT NULL,
                        descrizione TEXT,
                        prezzo      DECIMAL(6,2) NOT NULL,
                        immagine    VARCHAR(255),
                        disponibile TINYINT(1) NOT NULL DEFAULT 1,
                        FOREIGN KEY (categoria_id) REFERENCES categorie(id) ON DELETE CASCADE
                    ) ENGINE=InnoDB;
                """)
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS ordini (
                        id          INT AUTO_INCREMENT PRIMARY KEY,
                        numero      VARCHAR(20) NOT NULL UNIQUE,
                        stato       ENUM('in_attesa','in_preparazione','pronto','consegnato','annullato')
                                    NOT NULL DEFAULT 'in_attesa',
                        note        TEXT,
                        totale      DECIMAL(8,2) NOT NULL DEFAULT 0,
                        creato_il   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        aggiornato_il DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                                      ON UPDATE CURRENT_TIMESTAMP
                    ) ENGINE=InnoDB;
                """)
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS righe_ordine (
                        id          INT AUTO_INCREMENT PRIMARY KEY,
                        ordine_id   INT NOT NULL,
                        prodotto_id INT NOT NULL,
                        quantita    INT NOT NULL DEFAULT 1,
                        prezzo_unit DECIMAL(6,2) NOT NULL,
                        FOREIGN KEY (ordine_id)  REFERENCES ordini(id)  ON DELETE CASCADE,
                        FOREIGN KEY (prodotto_id) REFERENCES prodotti(id) ON DELETE RESTRICT
                    ) ENGINE=InnoDB;
                """)

                # Seed categorie
                for cat in ("Panini", "Menu", "Bevande", "Extra"):
                    cur.execute(
                        "INSERT IGNORE INTO categorie (nome) VALUES (%s)", (cat,)
                    )

                # Seed prodotti di esempio
                seed = [
                    ("Panini", "Classic Burger",
                     "Manzo 180g, lattuga, pomodoro, cipolla, salsa special",
                     7.90, "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400"),
                    ("Panini", "Cheese Lover",
                     "Doppio manzo, doppio cheddar, bacon, jalapeños",
                     9.50, "https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400"),
                    ("Panini", "Veggie Bliss",
                     "Burger di legumi, avocado, pomodori secchi, rucola",
                     8.20, "https://images.unsplash.com/photo-1520072959219-c595dc870360?w=400"),
                    ("Panini", "Smoky BBQ",
                     "Manzo affumicato, cipolla caramellata, salsa BBQ, cheddar",
                     9.90, "https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5?w=400"),
                    ("Menu",   "Menu Classic",
                     "Classic Burger + patatine + bevanda a scelta",
                     12.90, "https://images.unsplash.com/photo-1502508080486-06bfde62e306?w=400"),
                    ("Menu",   "Menu Cheese Lover",
                     "Cheese Lover + patatine grandi + bevanda a scelta",
                     14.50, "https://images.unsplash.com/photo-1608767221051-2b9d14071b41?w=400"),
                    ("Bevande","Coca-Cola 33cl", "Lattina ghiacciata",
                     2.50, "https://images.unsplash.com/photo-1554866585-cd94860890b7?w=400"),
                    ("Bevande","Acqua Naturale 50cl", "Acqua naturale fresca",
                     1.50, "https://images.unsplash.com/photo-1564419320461-6870880221ad?w=400"),
                    ("Bevande","Birra Artigianale 33cl", "Birra chiara locale alla spina",
                     4.00, "https://images.unsplash.com/photo-1535958636474-b021ee887b13?w=400"),
                    ("Extra",  "Patatine Classiche", "Patatine fritte croccanti con sale",
                     2.90, "https://images.unsplash.com/photo-1630384060421-cb20d0e0649d?w=400"),
                    ("Extra",  "Patatine con Cheddar", "Patatine con salsa cheddar calda",
                     3.50, "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400"),
                    ("Extra",  "Onion Rings", "Anelli di cipolla dorati",
                     3.20, "https://images.unsplash.com/photo-1639024471283-03518883512d?w=400"),
                ]
                for (cat, nome, desc, prezzo, img) in seed:
                    cur.execute(
                        "SELECT id FROM categorie WHERE nome=%s", (cat,)
                    )
                    row = cur.fetchone()
                    if row:
                        cur.execute(
                            """INSERT IGNORE INTO prodotti
                               (categoria_id, nome, descrizione, prezzo, immagine)
                               SELECT %s,%s,%s,%s,%s
                               WHERE NOT EXISTS
                               (SELECT 1 FROM prodotti WHERE nome=%s AND categoria_id=%s)""",
                            (row["id"], nome, desc, prezzo, img, nome, row["id"]),
                        )

    # ─────────────────────────── CATEGORIE ────────────────────────

    def get_categorie(self) -> list:
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT id, nome FROM categorie ORDER BY id")
                return cur.fetchall()

    def add_categoria(self, nome: str) -> int:
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("INSERT INTO categorie (nome) VALUES (%s)", (nome,))
                return cur.lastrowid

    # ─────────────────────────── PRODOTTI ─────────────────────────

    def get_menu(self) -> list:
        """Ritorna tutte le categorie con i relativi prodotti annidati."""
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT id, nome FROM categorie ORDER BY id")
                cats = cur.fetchall()
                for cat in cats:
                    cur.execute(
                        """SELECT id, nome, descrizione, prezzo,
                                  immagine, disponibile
                           FROM prodotti
                           WHERE categoria_id=%s
                           ORDER BY nome""",
                        (cat["id"],),
                    )
                    cat["prodotti"] = cur.fetchall()
                return cats

    def get_prodotti(self) -> list:
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT p.id, p.nome, p.descrizione, p.prezzo,
                           p.immagine, p.disponibile,
                           c.id AS categoria_id, c.nome AS categoria
                    FROM prodotti p
                    JOIN categorie c ON c.id = p.categoria_id
                    ORDER BY c.nome, p.nome
                """)
                return cur.fetchall()

    def get_prodotto(self, prodotto_id: int) -> dict | None:
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """SELECT p.*, c.nome AS categoria
                       FROM prodotti p JOIN categorie c ON c.id=p.categoria_id
                       WHERE p.id=%s""",
                    (prodotto_id,),
                )
                return cur.fetchone()

    def add_prodotto(self, categoria_id: int, nome: str, descrizione: str,
                     prezzo: float, immagine: str | None) -> int:
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """INSERT INTO prodotti
                       (categoria_id, nome, descrizione, prezzo, immagine)
                       VALUES (%s,%s,%s,%s,%s)""",
                    (categoria_id, nome, descrizione, prezzo, immagine),
                )
                return cur.lastrowid

    def update_prodotto(self, prodotto_id: int, **fields) -> bool:
        allowed = {"categoria_id", "nome", "descrizione",
                   "prezzo", "immagine", "disponibile"}
        updates = {k: v for k, v in fields.items() if k in allowed}
        if not updates:
            return False
        set_clause = ", ".join(f"{k}=%s" for k in updates)
        values = list(updates.values()) + [prodotto_id]
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    f"UPDATE prodotti SET {set_clause} WHERE id=%s", values
                )
                return cur.rowcount > 0

    def delete_prodotto(self, prodotto_id: int) -> bool:
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("DELETE FROM prodotti WHERE id=%s", (prodotto_id,))
                return cur.rowcount > 0

    # ─────────────────────────── ORDINI ───────────────────────────

    def _next_numero_ordine(self, cur) -> str:
        from datetime import datetime
        cur.execute(
            "SELECT COUNT(*)+1 AS n FROM ordini WHERE DATE(creato_il)=CURDATE()"
        )
        n = cur.fetchone()["n"]
        return f"ORD-{datetime.now():%Y%m%d}-{n:03d}"

    def crea_ordine(self, righe: list[dict], note: str = "") -> dict:
        """
        righe = [{"prodotto_id": X, "quantita": Y}, ...]
        Ritorna {"id": ..., "numero": ...}
        """
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                numero = self._next_numero_ordine(cur)

                # calcola totale
                totale = 0.0
                for r in righe:
                    cur.execute(
                        "SELECT prezzo FROM prodotti WHERE id=%s AND disponibile=1",
                        (r["prodotto_id"],),
                    )
                    p = cur.fetchone()
                    if not p:
                        raise ValueError(
                            f"Prodotto {r['prodotto_id']} non trovato o non disponibile"
                        )
                    r["_prezzo"] = float(p["prezzo"])
                    totale += r["_prezzo"] * r["quantita"]

                cur.execute(
                    "INSERT INTO ordini (numero, note, totale) VALUES (%s,%s,%s)",
                    (numero, note, totale),
                )
                ordine_id = cur.lastrowid

                for r in righe:
                    cur.execute(
                        """INSERT INTO righe_ordine
                           (ordine_id, prodotto_id, quantita, prezzo_unit)
                           VALUES (%s,%s,%s,%s)""",
                        (ordine_id, r["prodotto_id"], r["quantita"], r["_prezzo"]),
                    )

                return {"id": ordine_id, "numero": numero, "totale": totale}

    def get_ordini(self, stato: str | None = None) -> list:
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                if stato:
                    cur.execute(
                        """SELECT id, numero, stato, note, totale,
                                  creato_il, aggiornato_il
                           FROM ordini WHERE stato=%s
                           ORDER BY creato_il DESC""",
                        (stato,),
                    )
                else:
                    cur.execute(
                        """SELECT id, numero, stato, note, totale,
                                  creato_il, aggiornato_il
                           FROM ordini ORDER BY creato_il DESC LIMIT 100"""
                    )
                ordini = cur.fetchall()
                for o in ordini:
                    cur.execute(
                        """SELECT r.quantita, r.prezzo_unit,
                                  p.nome AS prodotto
                           FROM righe_ordine r
                           JOIN prodotti p ON p.id=r.prodotto_id
                           WHERE r.ordine_id=%s""",
                        (o["id"],),
                    )
                    o["righe"] = cur.fetchall()
                    # serializza datetime
                    o["creato_il"]     = str(o["creato_il"])
                    o["aggiornato_il"] = str(o["aggiornato_il"])
                return ordini

    def get_ordine(self, ordine_id: int) -> dict | None:
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """SELECT id, numero, stato, note, totale,
                              creato_il, aggiornato_il
                       FROM ordini WHERE id=%s""",
                    (ordine_id,),
                )
                o = cur.fetchone()
                if not o:
                    return None
                cur.execute(
                    """SELECT r.id, r.quantita, r.prezzo_unit,
                              p.id AS prodotto_id, p.nome AS prodotto
                       FROM righe_ordine r
                       JOIN prodotti p ON p.id=r.prodotto_id
                       WHERE r.ordine_id=%s""",
                    (ordine_id,),
                )
                o["righe"] = cur.fetchall()
                o["creato_il"]     = str(o["creato_il"])
                o["aggiornato_il"] = str(o["aggiornato_il"])
                return o

    def update_stato_ordine(self, ordine_id: int, stato: str) -> bool:
        stati_validi = {
            "in_attesa", "in_preparazione", "pronto",
            "consegnato", "annullato"
        }
        if stato not in stati_validi:
            raise ValueError(f"Stato non valido: {stato}")
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "UPDATE ordini SET stato=%s WHERE id=%s", (stato, ordine_id)
                )
                return cur.rowcount > 0

    def get_stats(self) -> dict:
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT
                      COUNT(*) AS totale,
                      SUM(stato='in_attesa')      AS in_attesa,
                      SUM(stato='in_preparazione') AS in_preparazione,
                      SUM(stato='pronto')         AS pronti,
                      SUM(stato='consegnato')     AS consegnati,
                      COALESCE(SUM(CASE WHEN stato='consegnato'
                                   THEN totale END), 0) AS incasso
                    FROM ordini
                    WHERE DATE(creato_il) = CURDATE()
                """)
                return cur.fetchone()
=======
import os
import json
import pymysql
from pymysql import err as pymysql_err
import sqlite3
import base64
import tempfile
import pathlib


class DatabaseWrapper:
    def __init__(self):
        # Legge le credenziali da variabili d'ambiente per facilità di configurazione
        host = os.getenv('DB_HOST', 'mysql-3f12020f-galvani5d.j.aivencloud.com')
        user = os.getenv('DB_USER', 'avnadmin')
        password = os.getenv('DB_PASSWORD', 'AVNS_idAGBvmY7bsHyDkUXBM')
        database = os.getenv('DB_NAME', 'defaultdb')
        port = int(os.getenv('DB_PORT', '13861'))

        self.use_sqlite = False
        self.connection = None

        if host == 'IL_TUO_HOST_QUI' or not host:
            print('[DatabaseWrapper] DB_HOST non configurato: uso fallback SQLite locale')
            self._init_sqlite()
            return

        try:
            # support SSL CA for Aiven if provided via env
            ssl_ca_path = os.getenv('DB_SSL_CA_PATH')
            ssl_ca_b64 = os.getenv('DB_SSL_CA_B64')
            ssl_kwargs = None
            if ssl_ca_b64 and not ssl_ca_path:
                # scrive il certificato in un file temporaneo persistente nella cartella backend
                ca_file = pathlib.Path(os.path.join(os.getcwd(), 'aiven-ca.pem'))
                if not ca_file.exists():
                    ca_file.write_bytes(base64.b64decode(ssl_ca_b64))
                ssl_ca_path = str(ca_file)
            if ssl_ca_path:
                ssl_kwargs = {'ca': ssl_ca_path}

            connect_args = dict(
                host=host,
                user=user,
                password=password,
                database=database,
                port=port,
                cursorclass=pymysql.cursors.DictCursor,
                autocommit=False,
                connect_timeout=5,
            )
            if ssl_kwargs:
                connect_args['ssl'] = ssl_kwargs

            self.connection = pymysql.connect(**connect_args)
            print('[DatabaseWrapper] Connesso a MySQL:', host)
        except Exception as e:
            print('[DatabaseWrapper] Impossibile connettersi a MySQL:', e)
            print('[DatabaseWrapper] Uso fallback SQLite locale')
            self._init_sqlite()

    def _init_sqlite(self):
        self.use_sqlite = True
        # file persistente nella workspace
        db_path = os.path.join(os.getcwd(), 'backend_local.db')
        self.connection = sqlite3.connect(db_path, check_same_thread=False)
        self.connection.row_factory = sqlite3.Row

    def crea_tabelle_se_non_esistono(self):
        # Crea le tabelle appropriate per il DB in uso (MySQL o SQLite)
        try:
            if self.use_sqlite:
                cur = self.connection.cursor()
                cur.execute('''
                    CREATE TABLE IF NOT EXISTS prodotti (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT,
                        price REAL,
                        category TEXT,
                        image TEXT
                    )
                ''')
                cur.execute('''
                    CREATE TABLE IF NOT EXISTS ordini (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        items_json TEXT,
                        total_price REAL,
                        status TEXT DEFAULT 'nuovo'
                    )
                ''')
                self.connection.commit()
            else:
                with self.connection.cursor() as cursor:
                    cursor.execute("""
                        CREATE TABLE IF NOT EXISTS prodotti (
                            id INT AUTO_INCREMENT PRIMARY KEY,
                            name VARCHAR(100),
                            price DECIMAL(10,2),
                            category VARCHAR(50),
                            image TEXT
                        )
                    """)
                    cursor.execute("""
                        CREATE TABLE IF NOT EXISTS ordini (
                            id INT AUTO_INCREMENT PRIMARY KEY,
                            items_json TEXT,
                            total_price DECIMAL(10,2),
                            status VARCHAR(50) DEFAULT 'nuovo'
                        )
                    """)
                self.connection.commit()
        except Exception as e:
            print('[DatabaseWrapper] Errore creando tabelle:', e)
            # Se la creazione su MySQL fallisce, forziamo fallback a SQLite per poter lavorare in locale
            if not self.use_sqlite:
                print('[DatabaseWrapper] Forzo fallback a SQLite')
                self._init_sqlite()
                self.crea_tabelle_se_non_esistono()
            else:
                raise

        # seed di esempio per testing locale se la tabella prodotti è vuota
        try:
            menu = self.get_menu()
            if not menu:
                sample = [
                    ('Classic Burger', 'panini', 6.5, None),
                    ('Cheese Burger', 'panini', 7.5, None),
                    ('Coca-Cola', 'bevande', 2.0, None),
                    ('Menu Completo', 'menu', 10.0, None),
                ]
                for name, category, price, image in sample:
                    try:
                        self.add_product(name, category, price, image)
                    except Exception:
                        pass
        except Exception:
            # non blocchiamo l'avvio se il seed fallisce
            pass

    # --- Menu / prodotti ---
    def get_menu(self):
        try:
            if self.use_sqlite:
                cur = self.connection.cursor()
                cur.execute('SELECT * FROM prodotti ORDER BY id ASC')
                rows = cur.fetchall()
                return [dict(r) for r in rows]
            else:
                with self.connection.cursor() as cursor:
                    cursor.execute('SELECT * FROM prodotti ORDER BY id ASC')
                    return cursor.fetchall()
        except Exception as e:
            msg = str(e).lower()
            if 'doesn' in msg or 'does not exist' in msg or 'no such table' in msg:
                print('[DatabaseWrapper] get_menu: tabella prodotti mancante, ricreo tabelle')
                try:
                    self.crea_tabelle_se_non_esistono()
                    return self.get_menu()
                except Exception:
                    pass
            raise

    def add_product(self, name, category, price, image=None):
        try:
            if self.use_sqlite:
                cur = self.connection.cursor()
                cur.execute('INSERT INTO prodotti (name, price, category, image) VALUES (?, ?, ?, ?)', (name, price, category, image))
                self.connection.commit()
                return cur.lastrowid
            else:
                with self.connection.cursor() as cursor:
                    cursor.execute('INSERT INTO prodotti (name, price, category, image) VALUES (%s, %s, %s, %s)', (name, price, category, image))
                    self.connection.commit()
                    return cursor.lastrowid
        except Exception as e:
            msg = str(e).lower()
            if 'doesn' in msg or 'does not exist' in msg or 'no such table' in msg:
                print('[DatabaseWrapper] add_product: tabella prodotti mancante, ricreo tabelle')
                self.crea_tabelle_se_non_esistono()
                return self.add_product(name, category, price, image)
            raise

    def update_product(self, product_id, name=None, category=None, price=None, image=None):
        parts = []
        params = []
        if name is not None:
            parts.append('name=?' if self.use_sqlite else 'name=%s'); params.append(name)
        if category is not None:
            parts.append('category=?' if self.use_sqlite else 'category=%s'); params.append(category)
        if price is not None:
            parts.append('price=?' if self.use_sqlite else 'price=%s'); params.append(price)
        if image is not None:
            parts.append('image=?' if self.use_sqlite else 'image=%s'); params.append(image)
        if not parts:
            return False
        sql = 'UPDATE prodotti SET ' + ', '.join(parts) + (' WHERE id=?' if self.use_sqlite else ' WHERE id=%s')
        params.append(product_id)
        if self.use_sqlite:
            cur = self.connection.cursor()
            cur.execute(sql, tuple(params))
            self.connection.commit()
        else:
            with self.connection.cursor() as cursor:
                cursor.execute(sql, tuple(params))
            self.connection.commit()
        return True

    def delete_product(self, product_id):
        if self.use_sqlite:
            cur = self.connection.cursor()
            cur.execute('DELETE FROM prodotti WHERE id=?', (product_id,))
            self.connection.commit()
        else:
            with self.connection.cursor() as cursor:
                cursor.execute('DELETE FROM prodotti WHERE id=%s', (product_id,))
            self.connection.commit()

    # --- Ordini ---
    def get_orders(self):
        try:
            if self.use_sqlite:
                cur = self.connection.cursor()
                cur.execute('SELECT * FROM ordini ORDER BY id DESC')
                rows = cur.fetchall()
                return [dict(r) for r in rows]
            else:
                with self.connection.cursor() as cursor:
                    cursor.execute('SELECT * FROM ordini ORDER BY id DESC')
                    return cursor.fetchall()
        except Exception as e:
            msg = str(e).lower()
            if 'doesn' in msg or 'does not exist' in msg or 'no such table' in msg:
                print('[DatabaseWrapper] get_orders: tabella ordini mancante, ricreo tabelle')
                try:
                    self.crea_tabelle_se_non_esistono()
                    return self.get_orders()
                except Exception:
                    pass
            raise

    def add_order(self, items, total_price):
        items_json = json.dumps(items, ensure_ascii=False)
        try:
            if self.use_sqlite:
                cur = self.connection.cursor()
                cur.execute('INSERT INTO ordini (items_json, total_price, status) VALUES (?, ?, ?)', (items_json, total_price, 'nuovo'))
                self.connection.commit()
                return cur.lastrowid
            else:
                with self.connection.cursor() as cursor:
                    cursor.execute('INSERT INTO ordini (items_json, total_price, status) VALUES (%s, %s, %s)', (items_json, total_price, 'nuovo'))
                    self.connection.commit()
                    return cursor.lastrowid
        except Exception as e:
            msg = str(e).lower()
            if 'doesn' in msg or 'does not exist' in msg or 'no such table' in msg:
                print('[DatabaseWrapper] add_order: tabella ordini mancante, ricreo tabelle')
                self.crea_tabelle_se_non_esistono()
                return self.add_order(items, total_price)
            raise

    def update_order_status(self, order_id, status):
        if self.use_sqlite:
            cur = self.connection.cursor()
            cur.execute('UPDATE ordini SET status=? WHERE id=?', (status, order_id))
            self.connection.commit()
        else:
            with self.connection.cursor() as cursor:
                cursor.execute('UPDATE ordini SET status=%s WHERE id=%s', (status, order_id))
            self.connection.commit()

>>>>>>> 690fc1a (inizio del progetto, parte ordini e aggiunta al menù)
