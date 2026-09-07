# Gigio

Aplicativo de **Comunicação Aumentativa e Alternativa (CAA)** em Flutter, para
iPad e Android. Dá voz a quem não fala, com boards que a família controla e um
formato aberto que ninguém precisa pedir licença para levar embora.

## Estado

MVP funcional. A criança monta frases tocando símbolos, o app fala em português
do Brasil, e o cuidador edita o board dentro do próprio aplicativo.

## Princípios

**A tela é dado, não código.** Um board é um documento JSON; o UI Engine o
transforma em widgets. Por isso o editor de boards não é um subsistema à parte
— ele edita o mesmo modelo que o renderizador consome.

**Nada sai do dispositivo.** O app não declara permissão de internet. As frases
de uma criança revelam condição de saúde — dado pessoal sensível sob a LGPD —
então a garantia é estrutural, não uma promessa em política de privacidade.

**A aparência de um botão não determina o que ele faz.** É o que permitirá, mais
adiante, que o mesmo botão acenda uma luz em vez de dizer uma palavra.

## Rodando

```bash
flutter pub get
flutter run
```

Para o iPad (simulador ou aparelho):

```bash
flutter run -d ipad
```

Para gerar o APK:

```bash
flutter build apk --release
```

## Testes

```bash
flutter test
```

A suíte cobre mais que regressão funcional — ela trava decisões de arquitetura e
de privacidade:

| Arquivo | O que protege |
|---|---|
| `architecture_test.dart` | `lib/domain/` não pode importar Flutter |
| `security_test.dart` | Sem permissão de internet, sem telemetria, PIN sempre derivado |
| `default_board_test.dart` | O board padrão é válido, alcançável e tem o vocabulário nuclear |
| `data/json_board_store_test.dart` | Escrita atômica, backup, recuperação de corrupção |
| `features/communication_flow_test.dart` | Montar "eu quero água" atravessando páginas produz a fala correta |

## Editando o board

Mantenha pressionado o ícone de engrenagem por 2 segundos e informe o PIN.
**PIN inicial: `1234`** — troque-o.

Dois obstáculos são deliberados: a criança usa o app tocando símbolos
rapidamente, e nenhum toque comum deve abrir o editor por acidente.

> No iPad, ative também o **Acesso Guiado** (Ajustes → Acessibilidade). É ele
> que impede de verdade que a criança saia do app; o PIN protege apenas contra
> edição acidental.

## Documentação

- [`docs/prd.md`](docs/prd.md) — problema, usuários, escopo e não-objetivos
- [`docs/architecture.md`](docs/architecture.md) — camadas, patterns, privacidade e limitações

## Metodologia

O projeto usa o [BMad Method v6](https://github.com/bmad-code-org/BMAD-METHOD)
(módulo BMM, skills em `.claude/skills`), em nível de cerimônia baixo — que é o
uso previsto pelo planejamento adaptativo à escala da própria metodologia para
um MVP. O ciclo completo (SM → Dev → QA por story) entra a partir da v2.

## Créditos

Pictogramas: [Mulberry Symbols](https://mulberrysymbols.org), © Steve Lee,
licenciados sob CC BY-SA 2.0 UK. Ver `assets/symbols/LICENSE-Mulberry.txt`.
