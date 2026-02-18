#!/usr/bin/env python3
import os
import sys
import subprocess

# Vai nella cartella backend
os.chdir('/workspaces/HamburgeriaPolpo/backend')

# Attiva virtualenv e avvia
print("🚀 Avvio Backend Flask...")
print("=" * 50)

subprocess.run('python app.py', shell=True)
