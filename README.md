# APK Mandato - Cadastro de Campo

Aplicativo/prototipo mobile do Gabinete IA para cadastro de campo, leitura territorial,
demandas, agenda e relacionamento com a base.

## Rodar localmente

Na raiz do projeto:

```powershell
python -m http.server 8092 --bind 127.0.0.1
```

Depois acesse:

```text
http://127.0.0.1:8092/
```

Se a API real em `/api/v1` nao estiver disponivel, o app entra automaticamente em
modo local/demo para permitir login, visualizacao dos paineis e cadastro de dados
no navegador.

## Credencial demo

```text
E-mail: chefe@gabineteia.local
Senha: Senha@123
```

## Estrutura

- `index.html`, `styles.css`, `app.js`: prototipo web/mobile do cadastro de campo.
- `gabinete-ia/backend`: API FastAPI em evolucao.
- `gabinete-ia/mobile`: app Flutter em evolucao.
- `Logo APP Mobile.jpg`: logo usada na tela inicial do app.
