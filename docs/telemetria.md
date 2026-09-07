# Telemetria

## O que muda na postura de privacidade

Até aqui o Gigio não declarava permissão de rede, e isso tornava o vazamento
**estruturalmente impossível**. Com a telemetria, a permissão passou a ser
necessária, e a garantia mudou de natureza: de **estrutural** para
**verificada**. É mais fraca, e o registro dessa troca é parte do trabalho.

O que substitui a garantia antiga:

| Controle | Onde |
|---|---|
| Só `lib/engines/telemetry/` pode fazer rede | `test/security_test.dart` falha o build se outra camada abrir conexão |
| Tela e toque exigem consentimento parental | `HttpTelemetry.registrar` descarta na origem |
| Rótulo e texto falado nunca sobem | Não existem nos eventos; teste garante |
| Redação na borda | `worker/src/index.js` revalida contra lista de permitidos |
| Build sem endpoint não faz rede | `_telemetriaUrl` vazio por padrão |

## Arquitetura

```
App  →  eventos  →  Cloudflare Worker  →  Datadog
                          ↓
              lista de campos permitidos
              descarta o que não reconhece
```

O app nunca fala com o Datadog diretamente: a chave de API fica no Worker, como
secret binding.

## O que sobe

**Sempre (técnico):** travamentos e erros fatais, falha de inicialização do TTS,
carregamento do board (nº de páginas e botões), e **se a recuperação de board
corrompido foi acionada** — métrica que antes não existia.

**Só com consentimento parental:** página aberta (`tela`) e botão tocado
(`toque`, pelo *id*, nunca pelo rótulo).

**Nunca:** texto de frase, rótulo de botão, id de símbolo, foto, nome, e-mail.
Estes estão numa lista de proibidos que **descarta o evento inteiro** no Worker.

## Identidade

Não há login, então não existe "usuário logado". Há um id de instalação
aleatório e local, e um id de sessão. Associar a comunicação de uma criança a
uma identidade estável seria o pior desenho possível.

## Consentimento

Desligado por padrão. Fica em Configurações, atrás do PIN do cuidador, com um
diálogo que explica em português claro o que passa a ser enviado — inclusive que
saber quais páginas foram abertas revela sobre dor, desconforto e recusa.

Revogar descarta também o que ainda não subiu: vale para o passado recente, não
só para o futuro.

## Publicar o Worker

```bash
cd worker
npx wrangler secret put DD_API_KEY
npx wrangler deploy
node test.mjs   # testes da redação
```

## Compilar o app com telemetria

```bash
flutter build ios --release \
  --dart-define=GIGIO_TELEMETRIA_URL=https://gigio-telemetria.<sub>.workers.dev
```

Sem o `--dart-define`, a telemetria é a implementação vazia e **nenhuma rede é
feita**. Esquecer de configurar resulta em privacidade, não em vazamento.

## Contexto de uso

Conta pessoal do Datadog, uso familiar, estudo pessoal, sem publicação
comercial. O consentimento parental aqui é do próprio responsável legal.
