import os

BASE_DIR = os.path.dirname(__file__)
DATA_DIR = os.path.join(BASE_DIR, 'data')
DB_PATH = os.path.join(DATA_DIR, 'data.db')
DB_CONFIG = {
    "host": "mysql-25a0ead7-iisgalvanimi-f8ab.l.aivencloud.com",
    "user": "avnadmin",
    "password": "AVNS_8GZK3ru4NNrOTGU8JvH",
    "database": "defaultdb",
    "port": 10630
}