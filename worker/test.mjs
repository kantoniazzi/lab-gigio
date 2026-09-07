// Testes da redação na borda. Rodar: node worker/test.mjs
import assert from 'node:assert';
import { sanitizar } from './src/index.js';

const base = { tipo: 'erro', appVersion: '1.0.0', plataforma: 'ios' };

assert.ok(sanitizar({ ...base, classe: 'SpeechError' }), 'evento técnico deve passar');

assert.equal(sanitizar({ ...base, frase: 'eu quero água' }), null,
  'evento com frase da criança deve ser DESCARTADO por inteiro');
assert.equal(sanitizar({ tipo: 'toque', pagina: '5', rotulo: 'dói' }), null,
  'rótulo de botão deve derrubar o evento');
assert.equal(sanitizar({ tipo: 'toque', pagina: '5' }), null,
  'toque sem consentimento deve ser descartado');
assert.ok(sanitizar({ tipo: 'toque', pagina: '5', consentido: true }),
  'toque com consentimento passa');
assert.equal(sanitizar({ tipo: 'inventado', x: 1 }), null,
  'tipo desconhecido deve ser descartado');

const limpo = sanitizar({ ...base, classe: 'X', campoNovo: 'surpresa' });
assert.equal(limpo.campoNovo, undefined, 'campo não previsto deve ser removido');

console.log('worker: todos os testes passaram');
