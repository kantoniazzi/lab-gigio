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

---

## RUM do Datadog

A partir da instrumentação com `datadog_flutter_plugin`, o app envia **views,
actions e erros** direto ao Datadog RUM.

### Consequência que precisa estar registrada

O SDK do Datadog **não passa pelo Worker do Cloudflare**. A redação na borda
deixou de proteger esses dados. O substituto são os *event mappers*, que rodam
**no aparelho** antes do envio:

| Evento | Pode ser descartado? | Barreira |
|---|---|---|
| `view` | **Não** — o mapper retorna tipo não-anulável | Barrado na origem: `startView` só é chamado com consentimento, e nenhum observador automático de navegação está ligado |
| `action` | Sim | Descartado pelo `actionEventMapper` sem consentimento |
| `error` | Sim | Sempre passa (é técnico), com atributos limpos |

Em todos os casos, atributos cuja chave contenha `label`, `rotulo`, `frase`,
`texto`, `simbolo` e afins são removidos antes do envio.

A garantia passou de **redação no servidor** para **redação no cliente**: mais
fraca, porque roda no dispositivo em vez de um ponto que o responsável controla.

### Decisão registrada: por que o RUM não passa pelo Worker

`DatadogRumConfiguration` aceita `customEndpoint`, o que permitiria rotear o RUM
pelo Worker e recuperar a redação no servidor. **Avaliado e deliberadamente não
implementado.**

O que exigiria: aceitar os caminhos do intake, descomprimir o corpo (o SDK envia
gzip; o Workers tem `DecompressionStream`), parsear NDJSON, aplicar a lista de
permitidos, recomprimir e repassar. Cerca de uma sessão de trabalho.

O que pesou contra: o formato do intake **não é API pública documentada**. Uma
atualização do SDK pode mudá-lo, e a telemetria pararia até alguém corrigir.

O que pesou a favor de não fazer: para uso pessoal e familiar, com a conta do
próprio responsável, a redação no aparelho já cobre o risco real.

**Se o Gigio deixar de ser familiar** — outras crianças, outras famílias — esta
decisão precisa ser revista. Aí a redação rodar dentro de um app que qualquer um
pode modificar deixa de ser aceitável, e o roteamento pelo Worker passa de luxo a
obrigação. Nesse caso, implementar com **lista de permitidos** e não de
proibidos, para que mudança de formato cause perda de telemetria (visível) em vez
de vazamento silencioso (falha aberta).

### Sobre as credenciais, para não haver confusão

| Credencial | Onde vive | Extraível do app? |
|---|---|---|
| **API Key** | Só no Worker, como secret | Não. Nunca esteve no app |
| **Application Key** | Não é usada no projeto | — |
| **Client token** (`pub...`) | Embutido no app | Sim, **e é por design** |
| **Application ID** do RUM | Embutido no app | Sim, por design |

O client token é **somente-escrita**: permite enviar dados falsos para a
organização, não ler nada. Rotear pelo Worker não resolveria isso de verdade —
apenas moveria a porta aberta para a URL do Worker. O ganho do roteamento é
redação, não proteção de credencial.

### Identidade

**Não há login.** A distribuição é por TestFlight sem contas, então "usuário
logado" não existe. O que vai para `setUserInfo`:

- `id`: id de instalação aleatório, gerado no aparelho, sem relação com pessoa
- `name`: apelido que o cuidador digitar, ou `instalação abc123`
- `extraInfo`: contexto do aparelho

Inventar uma identidade estável ligada à comunicação de uma criança seria o
desenho mais sensível possível. Quando houver login, troca-se a origem do id.

### Nome do dispositivo

**Limitação do iOS:** desde o iOS 16, a Apple não devolve o nome atribuído pelo
usuário ("iPad da Gigi") sem *entitlement* especial — retorna o modelo. No
Android o nome real costuma vir.

### Compilar com RUM

```bash
flutter build ios --release \
  --dart-define=GIGIO_DD_CLIENT_TOKEN=pub... \
  --dart-define=GIGIO_DD_APP_ID=... \
  --dart-define=GIGIO_DD_ENV=familia
```

Sem as duas primeiras, o app cai para o Worker; sem nenhuma, para a
implementação vazia, e **nenhuma rede é feita**.


---

## Session Replay

Ligado a **100%** das sessões amostradas pelo RUM (`replaySampleRate: 100`).
Ambiente: **`prod`**.

### Níveis de privacidade e por que cada um

| Ajuste | Valor | Motivo |
|---|---|---|
| `textAndInputPrivacyLevel` | `maskSensitiveInputs` | Mostra o texto da interface, mas mantém oculto o que for campo protegido. O **PIN do cuidador** usa `obscureText` e continua invisível na gravação |
| `imagePrivacyLevel` | `maskNonAssetsOnly` | Grava só imagens embarcadas. Com o padrão `maskAll` o board apareceria em branco e a gravação seria inútil |
| `touchPrivacyLevel` | `show` | Mostrar onde a criança tocou é o ponto da gravação |

### O que isso implica, dito de forma direta

A gravação reconstrói visualmente a Gigi se comunicando: os símbolos que ela
toca, a barra de frase com as palavras dela, a sequência inteira.

E os pictogramas PODD **e as fotos de pessoas** são assets embarcados — então
aparecem. Isso inclui **terceiros que não consentiram**: Profa Priscila, Tia
Natália e Tia Vivi, cujas fotos estão na página de Pessoas do livro.

Decisões anteriores sobre telemetria alcançavam dados da própria família. Esta
alcança outras pessoas. Registrado como escolha consciente do usuário, para uso
pessoal, em conta pessoal do Datadog, sem publicação comercial.

**Se o Gigio deixar de ser familiar**, isto precisa ser revisto antes de
qualquer outra coisa: gravar a tela de uma criança se comunicando, com rostos de
terceiros, é o dado mais sensível que este app pode produzir.

Para desligar sem mexer no resto: `replaySampleRate: 0`.

### Observação sobre o pacote

`datadog_session_replay` está em **preview** (`1.0.0-preview.7`). API pode mudar.
