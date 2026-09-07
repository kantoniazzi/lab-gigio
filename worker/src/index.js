/**
 * Proxy de telemetria do Gigio.
 *
 * Fica entre o app e o Datadog por duas razões, e a segunda é a que importa:
 *
 * 1. As credenciais do Datadog ficam aqui, como secret binding, e não no
 *    binário do app.
 * 2. **Redação na borda.** Este Worker valida cada evento contra uma lista de
 *    campos permitidos e DESCARTA qualquer coisa fora dela. Se alguém no futuro
 *    acrescentar um campo no app por descuido, ele morre aqui.
 *
 * Contexto que justifica o rigor: o Gigio é usado por uma criança, e o que ela
 * "diz" é dado pessoal sensível de saúde (LGPD art. 11) de titular criança
 * (art. 14). Este Worker é a última barreira antes de esse dado sair do
 * controle da família.
 */

/** Campos aceitos em qualquer evento. Tudo fora disto é descartado. */
const CAMPOS_COMUNS = new Set([
  'tipo', 'sessao', 'instalacao', 'appVersion', 'schemaVersion',
  'plataforma', 'osVersion', 'modelo', 'locale', 'ts',
]);

/** Campos adicionais aceitos por tipo de evento. */
const CAMPOS_POR_TIPO = {
  erro: new Set(['classe', 'mensagem', 'fatal']),
  desempenho: new Set(['metrica', 'valorMs']),
  voz: new Set(['ok', 'motivo']),
  board: new Set(['acao', 'paginas', 'botoes', 'recuperadoDeBackup']),
  // Navegação e toque só existem com consentimento parental explícito. O campo
  // `consentido` é reconferido aqui: defesa em profundidade, não confiança no
  // cliente.
  tela: new Set(['pagina', 'consentido']),
  toque: new Set(['pagina', 'botao', 'acaoBotao', 'consentido']),
};

const TIPOS_QUE_EXIGEM_CONSENTIMENTO = new Set(['tela', 'toque']);

/** Nunca aceitar, em nenhuma hipótese: é a fala da criança. */
const CAMPOS_PROIBIDOS = new Set([
  'frase', 'sentence', 'texto', 'textoFalado', 'utterance',
  'rotulo', 'label', 'simbolo', 'symbol', 'palavra', 'word',
  'foto', 'photo', 'imagem', 'nome', 'email',
]);

export function sanitizar(evento) {
  if (typeof evento !== 'object' || evento === null) return null;

  const permitidosDoTipo = CAMPOS_POR_TIPO[evento.tipo];
  if (!permitidosDoTipo) return null; // tipo desconhecido: descarta

  if (TIPOS_QUE_EXIGEM_CONSENTIMENTO.has(evento.tipo) && evento.consentido !== true) {
    return null;
  }

  const limpo = {};
  for (const [chave, valor] of Object.entries(evento)) {
    if (CAMPOS_PROIBIDOS.has(chave)) return null; // evento inteiro é suspeito
    if (!CAMPOS_COMUNS.has(chave) && !permitidosDoTipo.has(chave)) continue;
    if (typeof valor === 'string' && valor.length > 512) continue;
    limpo[chave] = valor;
  }
  return limpo.tipo ? limpo : null;
}

function cors() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return new Response(null, { headers: cors() });
    if (request.method !== 'POST') {
      return new Response('Método não permitido', { status: 405, headers: cors() });
    }

    let corpo;
    try {
      corpo = await request.json();
    } catch {
      return new Response('JSON inválido', { status: 400, headers: cors() });
    }

    const entrada = Array.isArray(corpo) ? corpo : [corpo];
    if (entrada.length > 100) {
      return new Response('Lote grande demais', { status: 413, headers: cors() });
    }

    const limpos = entrada.map(sanitizar).filter(Boolean);
    if (limpos.length === 0) {
      // 204 e não erro: telemetria jamais pode alterar o comportamento do app.
      return new Response(null, { status: 204, headers: cors() });
    }

    const payload = limpos.map((e) => ({
      ddsource: 'gigio',
      service: 'gigio-app',
      ddtags: `versao:${e.appVersion ?? 'desconhecida'},plataforma:${e.plataforma ?? 'desconhecida'}`,
      ...e,
    }));

    const resposta = await fetch(
      `https://http-intake.logs.${env.DD_SITE ?? 'datadoghq.com'}/api/v2/logs`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'DD-API-KEY': env.DD_API_KEY },
        body: JSON.stringify(payload),
      },
    );

    return new Response(null, { status: resposta.ok ? 202 : 502, headers: cors() });
  },
};
