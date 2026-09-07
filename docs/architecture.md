# Gigio — Arquitetura

## A decisão central: a tela é dado, não código

```
JSON (board) ──► BoardRepository ──► Board/BoardPage ──► GridRenderer ──► AacButton
                                          ▲
                                    BoardEditorScreen
```

Uma página não é escrita à mão em Dart; ela é *calculada* a partir de um
modelo. Três consequências, todas intencionais:

1. **O editor de boards fica barato.** Ele edita o mesmo modelo que o
   renderizador lê. Não existe caminho paralelo nem formato intermediário.
2. **Import/export é o próprio formato de armazenamento.** Não há tradução.
3. **A UI pode ser trocada inteira sem tocar no vocabulário.**

A segunda decisão que sustenta tudo: **a aparência de um botão não determina o
que ele faz**. `AacButton` carrega uma `ButtonAction` polimórfica. É isso que
permitirá, na v3, que o mesmo botão verde acenda uma luz em vez de dizer uma
palavra.

## Camadas

```
lib/
├── core/                 infraestrutura sem regra de negócio
│   ├── design_system/    tokens + componentes visuais
│   ├── symbols/          catálogo de pictogramas
│   ├── result/           Result<T> — erro como valor
│   └── errors/           AppError selado
├── domain/               ⚠️ DART PURO — não importa Flutter
│   └── models/           Board, BoardPage, AacButton, ButtonAction, Sentence
├── engines/
│   ├── ui_engine/        GridRenderer: modelo → widgets
│   ├── speech/           SpeechProvider (Strategy) + NativeTtsProvider
│   └── intent_engine/    reservado para a v3 (casa inteligente)
├── data/                 BoardRepository + JsonBoardStore
└── features/
    ├── communication/    tela principal + controlador
    └── editor/           editor de boards + PIN do cuidador
```

**A fronteira do domínio é testada, não sugerida.**
`test/architecture_test.dart` falha o build se alguém importar Flutter dentro
de `lib/domain/`. O núcleo de comunicação precisa continuar testável e portável
sem arrastar a UI junto.

## Patterns e por que cada um está aqui

| Pattern | Onde | Por quê |
|---|---|---|
| **Sealed classes** | `ButtonAction`, `AppError`, `Result` | `switch` exaustivo verificado em compilação. Adicionar um tipo de ação novo quebra o build em todo lugar que precisa tratá-lo — nenhum botão pode ficar sem comportamento |
| **Strategy** | `SpeechProvider` | ElevenLabs entra depois sem tocar no núcleo |
| **Repository** | `BoardRepository` | Migrar JSON → Drift na v2 vira detalhe de implementação |
| **Result como valor** | fronteiras de I/O | Numa CAA, falha silenciosa = criança sem voz. O chamador é obrigado a tratar o erro |
| **Design tokens** | `GigioColors` etc. | Tema de alto contraste ou fonte maior = mudar um arquivo |
| **Modelo imutável** | `Board`, `Sentence` | Elimina bugs de estado compartilhado; desfazer fica trivial |

### Por que JSON e não Drift/SQLite (por enquanto)

A transcrição original propunha Drift + SQLite. Um board, porém, é um
*documento*, não dado relacional — e JSON já é exatamente o formato de
import/export desejado, sem camada de tradução, e sem *code generation*.

Drift ganha sentido na v2, quando entrarem **histórico de uso e predição de
palavras** — aí sim há consulta relacional de verdade. `BoardRepository` existe
para que essa troca não vaze para o resto do app.

## Privacidade e segurança

O usuário final é uma criança. O histórico de frases revela condição de saúde,
o que o torna **dado pessoal sensível** (LGPD art. 11); sendo criança, o art. 14
exige consentimento específico de um dos pais.

A postura do MVP é **nenhum dado sai do dispositivo**:

| Controle | Implementação |
|---|---|
| Sem rede | `INTERNET` removida do manifesto com `tools:node="remove"`, impedindo reintrodução por fusão de manifestos de bibliotecas |
| Sem telemetria | Nenhum SDK de analytics ou crash reporting; travado por teste |
| Histórico | Não é persistido |
| PIN do cuidador | PBKDF2-HMAC-SHA256, 120k iterações, salt aleatório por dispositivo, guardado no Keychain/Keystore, comparação em tempo constante |
| Import de board | Validado contra schema; ações desconhecidas rejeitadas; integridade referencial de navegação verificada |
| Símbolos | Board referencia *id*, nunca caminho de arquivo — elimina *path traversal* |
| Integridade | Escrita atômica (temp → rename) com backup e recuperação automática |

`test/security_test.dart` transforma essas garantias em falha de build, porque
são fáceis de perder por acidente.

### Limitações que precisam ser ditas em voz alta

- **O PIN não resiste a um adversário com posse do aparelho.** Quatro dígitos
  são 10 mil combinações; nenhuma quantidade de iterações resolve isso. O
  objetivo dele é impedir que a *criança* entre no editor por acidente. A
  proteção real contra terceiros é o **Acesso Guiado** do iPad, no nível do
  sistema operacional.
- **No build web, o armazenamento seguro é mais fraco.** O
  `flutter_secure_storage` recai sobre o armazenamento do navegador, que não
  tem equivalente ao Keychain. O PIN continua hasheado, mas o isolamento é menor.
- **Debug e profile declaram INTERNET.** É o Flutter que exige, para hot reload
  e DevTools. Apenas o build de release é auditado.

## Acessibilidade

- Alvo mínimo de toque de 44pt (HIG da Apple); o layout expande as células além
  disso sempre que há espaço.
- Cores da **Fitzgerald Key** escurecidas em relação às tradicionais para
  alcançar contraste WCAG AA com texto preto — o amarelo saturado clássico falha.
- Rótulos encolhem em vez de quebrar no meio da palavra.
- `Semantics` em botões e na barra de frase, para VoiceOver.
- Retorno auditivo a cada toque.

## O que a v2+ deve encontrar pronto

| Evolução | O que já existe |
|---|---|
| ElevenLabs | `SpeechProvider` + cache de áudio encaixam como novo provider |
| Predição de palavras | `Sentence` imutável dá histórico de graça; Drift entra por trás do `BoardRepository` |
| Casa inteligente | `engines/intent_engine/` reservado; basta um novo `ButtonAction` |
| Múltiplos perfis | `BoardRepository` já abstrai "qual board está ativo" |
| Temas / alto contraste | Todos os valores visuais já são tokens |

## Regenerar os pictogramas

```bash
git clone --depth 1 https://github.com/mulberrysymbols/mulberry-symbols.git /tmp/mulberry
dart run tool/curate_symbols.dart /tmp/mulberry
```

O script copia apenas os símbolos mapeados, **achata as classes CSS em atributos
de apresentação** (o `flutter_svg` não interpreta blocos `<style>`, e sem isso os
símbolos renderizam como manchas pretas) e regenera `symbol_manifest.g.dart`.

O repositório Mulberry não é dependência de build: o resultado é versionado, o
que mantém a compilação offline e o conjunto de símbolos auditável no diff.

Pictogramas: Mulberry Symbols, © Steve Lee, CC BY-SA 2.0 UK —
<https://mulberrysymbols.org>
