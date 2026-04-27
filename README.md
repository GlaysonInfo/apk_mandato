# Gabinete IA - App Mobile

Aplicativo mobile do Gabinete IA para cadastro de campo, visitas, demandas,
agenda e sincronizacao offline.

## Rodar localmente

O app principal esta em `gabinete-ia/mobile`.

```powershell
cd gabinete-ia\mobile
flutter run
```

O backend de apoio esta em `gabinete-ia/backend`.

```powershell
cd gabinete-ia\backend
uvicorn main:app --reload --port 8010
```

Para apontar o app Flutter para uma API especifica, use:

```powershell
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8010
```

## Estrutura

- `gabinete-ia/backend`: API FastAPI em evolucao.
- `gabinete-ia/mobile`: app Flutter em evolucao.
- `gabinete-ia/mobile/assets/images/logo_app_mobile.jpg`: logo usada no app.
