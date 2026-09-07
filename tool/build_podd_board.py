# -*- coding: utf-8 -*-
"""Gera o board PODD da Gigi a partir da transcrição manual das páginas.

A geometria e as imagens vêm de tool/extract_podd_book.dart (tool/podd_cells.json);
a SEMÂNTICA — rótulo, fala, ação e destino — é transcrita à mão a partir das
páginas renderizadas. É deliberado: um selo mapeado para o destino errado manda
a criança para outra página no meio de uma frase, e isso é caro demais para
confiar a OCR.
"""
import json, sys

CELLS = json.load(open('tool/podd_cells.json'))

W = 'word'      # adiciona à barra de frase
S = 'speak'     # fala a frase pronta, sem entrar na barra
N = 'nav'       # vai para outra página
B = 'back'      # volta na pilha

# pdf: id-da-pagina-no-livro
PAGE_OF_PDF = {1:'1a', 2:'2a', 3:'2b', 4:'3', 5:'4', 6:'5', 10:'9', 11:'9a', 12:'10a', 18:'11a'}

# (pdf, {slot: (rotulo, tipo, valor)})
PAGES = {
 1: {'name':'Página 1',
  'g':{
   'r0c0':('eu',W,'eu'), 'r0c1':('parar',W,'parar'), 'r0c2':('mais',W,'mais'),
   'r0c3':('Mais a Dizer',N,'2a'),
   'r1c0':('você',W,'você'), 'r1c1':('ajudar',W,'ajudar'), 'r1c2':('acabar',W,'acabou'),
   'r1c3':('eu não sei',S,'Eu não sei.'),
   'r2c0':('Uh oh!',S,'Uh oh! Oh não!'), 'r2c1':('vem',W,'vem'), 'r2c2':('olhar',W,'olhar'),
   'r2c3':('Outra Coisa',N,'2a'),
  },
  's':{'s1':('ooops',S,'Ooops! Eu me enganei.')}},

 2: {'name':'Página 2',
  'g':{
   'r0c0':('é hora de',W,'é hora de'), 'r0c1':('eu tenho uma pergunta',N,'8'),
   'r0c2':('eu quero fazer',N,'11a'), 'r0c3':('eu gosto',N,'3'),
   'r1c0':('eu quero te contar',S,'Eu quero te contar uma coisa.'),
   'r1c1':('arrumar',W,'arrumar'), 'r1c2':('vamos ir',N,'12'),
   'r1c3':('eu não gosto disso',N,'4'),
   'r2c0':('banheiro',S,'Eu tenho que ir ao banheiro.'),
   'r2c1':('eu quero te mostrar algo',N,'2b'),
   'r2c2':('fazer',N,'10a'), 'r2c3':('algo está errado',N,'5'),
  },
  's':{'s0':('voltar para a página 1',N,'1a'), 's1':('ooops',S,'Ooops! Eu me enganei.')}},

 3: {'name':'Mostrar',
  'g':{
   'r0c0':('eu',W,'eu'), 'r0c1':('olhe pra mim',S,'Olhe pra mim!'),
   'r0c2':('isso',W,'isso'), 'r0c3':('quarto',W,'quarto'),
   'r1c0':('pegue meu comunicador',S,'Por favor, pegue meu comunicador.'),
   'r1c1':('fazer algo',W,'fazer algo'), 'r1c2':('dentro',W,'dentro'),
   'r1c3':('mochila',W,'mochila'),
   'r2c0':('perguntar a alguém',N,'9'), 'r2c1':('pegar',W,'pegar'),
   'r2c2':('novo',W,'novo'), 'r2c3':('algum outro lugar',N,'12'),
  },
  's':{'s0':('voltar para a página 1',N,'1a'), 's1':('ooops',S,'Ooops! Eu me enganei.'),
       's2':('voltar para a página 2',N,'2a')}},

 4: {'name':'Eu gosto',
  'g':{
   'r0c0':('bom',W,'bom'), 'r0c1':('engraçado',W,'engraçado'),
   'r0c2':('delícia',W,'delicioso'), 'r0c3':('especial',W,'especial'),
   'r1c0':('ótimo',W,'ótimo'), 'r1c1':('divertido',W,'divertido'),
   'r1c2':('favorito',W,'favorito'), 'r1c3':('tentar',W,'tentar'),
   'r2c0':('legal',W,'legal'), 'r2c1':('inteligente',W,'inteligente'),
   'r2c2':('lindo',W,'lindo'), 'r2c3':('ir para lista',N,'lista'),
  },
  's':{'s0':('voltar para a página 1',N,'1a'), 's1':('ooops',S,'Ooops! Eu me enganei.')}},

 5: {'name':'Eu não gosto',
  'g':{
   'r0c0':('ruim',W,'ruim'), 'r0c1':('eu não quero fazer isso',S,'Eu não quero fazer isso.'),
   'r0c2':('assustador',W,'assustador'), 'r0c3':('eca',W,'eca'),
   'r1c0':('safado',W,'safado'), 'r1c1':('eu não consigo',S,'Eu não consigo fazer isso.'),
   'r1c2':('entediante',W,'entediante'), 'r1c3':('vamos fazer outra coisa',N,'11a'),
   'r2c0':('bobo',W,'bobo'), 'r2c1':('barulhento',W,'barulhento'),
   'r2c2':('malvado',W,'malvado'), 'r2c3':('ir para lista',N,'lista'),
  },
  's':{'s0':('voltar para a página 1',N,'1a'), 's1':('ooops',S,'Ooops! Eu me enganei.')}},

 6: {'name':'Algo está errado',
  'g':{
   'r0c0':('doente',N,'6'), 'r0c1':('desconfortável',W,'desconfortável'),
   'r0c2':('cansado',W,'cansado'), 'r0c3':('eu quero alguém',N,'9'),
   'r1c0':('machucado',N,'6'), 'r1c1':('bateu',N,'6'),
   'r1c2':('bravo',W,'bravo'), 'r1c3':('fique comigo',S,'Fique comigo, por favor.'),
   'r2c0':('coceira',N,'6'), 'r2c1':('cortar',N,'6'),
   'r2c2':('triste',W,'triste'), 'r2c3':('virar a página',N,'5b'),
  },
  's':{'s0':('voltar para a página 1',N,'1a'), 's1':('ooops',S,'Ooops! Eu me enganei.')}},

 10:{'name':'Pessoas',
  'g':{
   'r0c0':('eu',W,'eu'), 'r0c1':('Vovó Sônia',W,'Vovó Sônia'),
   'r0c2':('menino',W,'menino'), 'r0c3':('amigos',N,'9a'),
   'r1c0':('Pai Kleber',W,'meu pai'), 'r1c1':('Vovô Adenir',W,'Vovô Adenir'),
   'r1c2':('menina',W,'menina'),
   'r2c0':('Mãe Camila',W,'minha mãe'), 'r2c1':('tio',W,'tio'), 'r2c2':('tia',W,'tia'),
   'r2c3':('virar a página',N,'9a'),
  },
  's':{'s0':('voltar para a página 1',N,'1a'), 's1':('ooops',S,'Ooops! Eu me enganei.')}},

 11:{'name':'Amigos',
  'g':{
   'r0c0':('Profa Priscila',W,'Professora Priscila'),
   'r1c0':('Tia Natália',W,'Tia Natália'), 'r1c1':('Tia Vivi',W,'Tia Vivi'),
   'r2c3':('outra pessoa',N,'lista'),
  },
  's':{'s0':('voltar para a página 1',N,'1a'), 's1':('ooops',S,'Ooops! Eu me enganei.'),
       's2':('voltar para a página 9',N,'9')}},

 12:{'name':'Ações',
  'g':{
   'r0c0':('não',W,'não'), 'r0c1':('pegar',W,'pegar'), 'r0c2':('ir',W,'ir'),
   'r0c3':('gostar',W,'gostar'),
   'r1c0':('fazer',W,'fazer'), 'r1c1':('dar',W,'dar'), 'r1c2':('vir',W,'vir'),
   'r1c3':('movimentos',N,'10d'),
   'r2c0':('ver',W,'ver'), 'r2c1':('falar',W,'falar'), 'r2c2':('AVD',N,'10b'),
   'r2c3':('virar a página',N,'10b'),
  },
  's':{'s0':('voltar para a página 1',N,'1a'), 's1':('ooops',S,'Ooops! Eu me enganei.')}},

 18:{'name':'Atividades',
  'g':{
   'r0c0':('não',W,'não'), 'r0c1':('abraçar',W,'abraçar'),
   'r0c2':('comer ou beber',N,'18'), 'r0c3':('atividades externas',N,'11e'),
   'r1c0':('querer',W,'querer'), 'r1c1':('descansar',W,'descansar'),
   'r1c2':('brinquedo',N,'11c'), 'r1c3':('brincadeiras com água',N,'43'),
   'r2c0':('música',N,'28'), 'r2c1':('assistir',N,'27'), 'r2c2':('livro',N,'29'),
   'r2c3':('virar a página',N,'11b'),
  },
  's':{'s0':('voltar para a página 1',N,'1a'), 's1':('ooops',S,'Ooops! Eu me enganei.')}},
}

def action(kind, value):
    if kind == W: return {'type':'addWord','word':value}
    if kind == S: return {'type':'speak','text':value}
    if kind == N: return {'type':'navigate','target':value}
    return {'type':'back'}

pages, targets = [], set()
for pdf, spec in PAGES.items():
    pid = PAGE_OF_PDF[pdf]
    cells = CELLS[str(pdf)]
    grid, side = [], []
    for slot, (label, kind, value) in spec['g'].items():
        r, c = int(slot[1]), int(slot[3])
        if kind == N: targets.add(value)
        grid.append({'id':f'{pid}-{slot}','label':label,'position':[r,c],
                     'symbol':cells[slot],'labelInImage':True,'action':action(kind,value)})
    for slot, (label, kind, value) in spec['s'].items():
        r = int(slot[1])
        if kind == N: targets.add(value)
        side.append({'id':f'{pid}-{slot}','label':label,'position':[r,0],
                     'symbol':cells[slot],'labelInImage':True,'action':action(kind,value)})
    pages.append({'id':pid,'name':spec['name'],'rows':3,'columns':4,
                  'buttons':grid,'sidebar':side})

# Stubs para destinos ainda não digitalizados. Preservam a posição do botão —
# que é a memória motora — em vez de removê-lo ou deixá-lo mudo.
have = {p['id'] for p in pages}
for t in sorted(targets - have):
    pages.append({'id':t,'name':f'Página {t}','rows':1,'columns':1,
      'buttons':[{'id':f'{t}-aviso','label':'Esta parte do livro ainda não foi digitalizada',
                  'position':[0,0],'wordClass':'system',
                  'action':{'type':'speak','text':'Esta parte do livro ainda não foi digitalizada.'}}],
      'sidebar':[{'id':f'{t}-voltar','label':'voltar','position':[0,0],
                  'wordClass':'system','symbol':'voltar','action':{'type':'back'}}]})

board = {'schemaVersion':2,'id':'podd-gigi','name':'Livro da Gigi (PODD)',
         'homePageId':'1a','pages':pages}
open('assets/boards/board_podd_gigi.json','w').write(
    json.dumps(board, ensure_ascii=False, indent=2))
print(f'{len(PAGES)} páginas transcritas + {len(pages)-len(PAGES)} stubs')
print('destinos:', ' '.join(sorted(targets)))
