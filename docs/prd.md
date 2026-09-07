# Gigio — PRD (MVP)

> Documento de nível baixo, conforme o planejamento adaptativo à escala do
> BMad v6. O ciclo completo (SM → Dev → QA por story) entra a partir da v2,
> usando as skills BMad instaladas em `.claude/skills`.

## Problema

Uma criança que não fala ou fala pouco precisa de uma forma de se comunicar.
Aplicativos de CAA consagrados, como o TD Snap, resolvem isso — mas são caros,
proprietários, e prendem o vocabulário construído pela família num formato
fechado.

O Gigio existe para dar a essa criança uma voz que a família controla, num
formato aberto, funcionando num iPad que já existe em casa.

## Usuários

**Criança (usuária primária).** Já usa CAA e constrói frases. Não se assume
alfabetização. Interage por toque direto. Precisa de:
- botões grandes e estáveis — símbolos que mudam de lugar destroem a memória
  motora que ela levou meses para construir;
- retorno auditivo imediato a cada toque, confirmando que funcionou;
- caminho óbvio de volta de qualquer página.

**Cuidador (usuário secundário).** Pai, mãe, terapeuta ou professor. Configura o
board. Precisa de:
- editar botões sem saber programar;
- não ter o board desconfigurado por acidente pela criança;
- levar o vocabulário embora, se quiser trocar de aplicativo.

## Requisitos do MVP

| # | Requisito | Status |
|---|---|---|
| R1 | Grade de símbolos renderizada a partir de um modelo declarativo | ✅ |
| R2 | Barra de frase que acumula palavras e fala a sentença | ✅ |
| R3 | Síntese de voz em português do Brasil, offline | ✅ |
| R4 | Navegação entre páginas, com volta garantida | ✅ |
| R5 | Editor de boards protegido contra acesso acidental | ✅ |
| R6 | Persistência local resiliente a corrupção | ✅ |
| R7 | Frases prontas que falam direto, sem montar | ✅ |
| R8 | Funcionamento 100% offline | ✅ |
| R9 | Rodar em iPad e Android a partir da mesma base de código | ✅ |

## Não-objetivos do MVP

Deliberadamente fora, com o motivo:

- **Sincronização em nuvem** — exigiria rede, e com ela toda uma superfície de
  ataque e de conformidade, para resolver um problema que ainda não existe (um
  dispositivo, um usuário).
- **ElevenLabs / voz clonada** — enviaria frases de uma criança para uma API
  externa. Ver `architecture.md`, seção de privacidade. Entra depois, como
  provider opcional com consentimento explícito.
- **Predição de palavras** — exige histórico de uso, que é justamente o dado
  mais sensível do app. Merece decisão consciente, não um efeito colateral.
- **Intent Engine / casa inteligente** — a costura arquitetural está reservada
  (`lib/engines/intent_engine/`), mas construí-la agora atrasaria a voz, que é
  o produto.
- **Múltiplos perfis de usuário** — um dispositivo, uma criança.
- **Varredura por switches** — importante para acessibilidade motora, mas não
  para esta criança, que usa toque direto.

## Métrica de sucesso do MVP

A criança consegue montar e falar "eu quero água" sem ajuda de um adulto, e o
cuidador consegue trocar um símbolo do board sem consultar ninguém.

## Riscos de produto

| Risco | Resposta |
|---|---|
| Os símbolos abstratos do Mulberry ("quero", "mais") não comunicam bem | O cuidador troca no editor; o campo símbolo é só um id no JSON |
| A grade 5x4 pode ser densa demais ou rala demais | Tamanho da grade é editável no próprio app |
| A voz nativa pode soar robótica demais | `SpeechProvider` permite trocar a engine sem mexer no núcleo |
