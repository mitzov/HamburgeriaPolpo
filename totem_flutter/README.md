# Totem Flutter (Cliente)

Piccolo progetto Flutter per il Totem cliente.

Prerequisiti:
- Flutter installato (nel devcontainer è già presente secondo la consegna)

Eseguire:

```bash
# dalla root del workspace
cd totem_flutter
flutter pub get
flutter run -d <device>
```

L'app chiama l'API backend su `http://127.0.0.1:5000` per `/menu` e `/orders`.
