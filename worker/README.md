# Worker de telemetria

Proxy entre o app e o Datadog. Existe por duas razões, e a segunda é a que
importa: as credenciais ficam fora do binário do app, e **os eventos passam por
uma lista de campos permitidos na borda**.

Se alguém acrescentar um campo no app por descuido, ele morre aqui. Rótulo de
botão, texto de frase, nome e foto estão numa lista de proibidos que descarta o
evento inteiro.

## Publicar

```bash
cd worker
npx wrangler secret put DD_API_KEY
npx wrangler deploy
```

## Testar a redação

```bash
curl -X POST https://gigio-telemetria.<subdominio>.workers.dev \
  -H 'Content-Type: application/json' \
  -d '{"tipo":"toque","pagina":"5","frase":"eu quero água"}'
# 204 — descartado: "frase" está na lista de proibidos
```
