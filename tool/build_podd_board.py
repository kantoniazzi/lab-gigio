# -*- coding: utf-8 -*-
"""Gera o board PODD da Gigi juntando geometria+imagens (tool/podd_cells.json)
com a transcrição manual da semântica (tool/podd_pages.py)."""
import json, importlib.util as u

spec = u.spec_from_file_location('podd_pages', 'tool/podd_pages.py')
mod = u.module_from_spec(spec); spec.loader.exec_module(mod)
PAGES, PAGE_OF_PDF = mod.PAGES, mod.PAGE_OF_PDF

data = json.load(open('tool/podd_cells.json'))
CELLS, LAYOUTS = data['cells'], data['layouts']

def action(kind, value):
    return {'word': {'type':'addWord','word':value},
            'speak':{'type':'speak','text':value},
            'nav':  {'type':'navigate','target':value},
            'back': {'type':'back'}}[kind]

pages, targets = [], set()

for pdf, spec_ in PAGES.items():
    pid = PAGE_OF_PDF[pdf]
    cells = CELLS[str(pdf)]
    grid, side = [], []
    for slot, (label, kind, value) in spec_['g'].items():
        if slot not in cells: continue
        if kind == 'nav': targets.add(value)
        grid.append({'id':f'{pid}-{slot}','label':label,'position':[int(slot[1]),int(slot[3])],
                     'symbol':cells[slot],'labelInImage':True,'action':action(kind,value)})
    for slot, (label, kind, value) in spec_['s'].items():
        if slot not in cells: continue
        if kind == 'nav': targets.add(value)
        side.append({'id':f'{pid}-{slot}','label':label,'position':[int(slot[1]),0],
                     'symbol':cells[slot],'labelInImage':True,'action':action(kind,value)})
    pages.append({'id':pid,'name':spec_['name'],'rows':3,'columns':4,
                  'buttons':grid,'sidebar':side})

# Páginas de lista: grade densa própria, medida na extração. Cada célula fala
# o próprio nome; o rótulo vem do desenho, então usamos o id da posição.
LIST_LABELS = {
 'lista-comida': ['','','','','','','',
   'panqueca','arroz','carne','danone','banana','batata','água de coco',
   'sanduíche','feijão','peixe','sorvete','mamão','cenoura','água',
   'bolo','purê','ovo','chocolate','laranja','milho','suco',
   'pizza','macarrão','frango','pudim','melão','brócolis','café',
   'hambúrguer','batata frita','porco','mousse','manga','alface','chá'],
}
for pdf, pid in PAGE_OF_PDF.items():
    if not pid.startswith('lista-'): continue
    layout = LAYOUTS[str(pdf)]
    cols, rows = (int(x) for x in layout.split('x'))
    cells = CELLS[str(pdf)]
    labels = LIST_LABELS.get(pid, [])
    buttons = []
    for r in range(rows):
        for c in range(cols):
            slot = f'r{r}c{c}'
            if slot not in cells: continue
            idx = r * cols + c
            label = labels[idx] if idx < len(labels) else ''
            if not label: continue
            buttons.append({'id':f'{pid}-{slot}','label':label,'position':[r,c],
                            'symbol':cells[slot],'labelInImage':True,
                            'action':{'type':'addWord','word':label}})
    # A volta vai para a coluna lateral, e não para a grade: nas listas todas
    # as células podem estar ocupadas por itens.
    pages.append({'id':pid,'name':pid.replace('lista-','Lista de '),
                  'rows':rows,'columns':cols,'buttons':buttons,
                  'sidebar':[{'id':f'{pid}-voltar','label':'voltar','position':[0,0],
                              'wordClass':'system','symbol':'voltar',
                              'action':{'type':'back'}}]})

# No livro de papel, algumas páginas só são alcançadas virando para a aba
# física. Como a faixa de abas não foi replicada, as ligações que existem
# apenas por esse meio são declaradas aqui — senão a página fica órfã.
LIGACOES_DE_ABA = [('50', '51', 'virar a página')]
por_id = {p['id']: p for p in pages}
for origem, destino, rotulo in LIGACOES_DE_ABA:
    if origem in por_id and destino in por_id:
        por_id[origem]['sidebar'].append({
            'id': f'{origem}-para-{destino}', 'label': rotulo, 'position': [2, 0],
            'wordClass': 'system', 'symbol': 'voltar',
            'action': {'type': 'navigate', 'target': destino}})

# Stubs para destinos ainda sem página. Preservam a posição do botão — que é a
# memória motora — em vez de removê-lo ou deixá-lo mudo.
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

real = len(PAGES) + sum(1 for p in PAGE_OF_PDF.values() if p.startswith('lista-'))
print(f'{real} páginas do livro + {len(pages)-real} stubs')
print('botões:', sum(len(p['buttons'])+len(p['sidebar']) for p in pages))
print('stubs:', ' '.join(sorted(targets - have)))
