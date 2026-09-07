# -*- coding: utf-8 -*-
"""Transcrição manual do livro PODD da Gigi.

Feita à mão a partir das páginas renderizadas, e não por OCR: um destino errado
manda a criança para outra página no meio de uma frase.

Formato por célula: (rótulo, tipo, valor)
  W = adiciona à barra de frase   S = fala frase pronta
  N = vai para outra página       B = volta na pilha
"""
W, S, N, B = 'word', 'speak', 'nav', 'back'

OOOPS = ('ooops', S, 'Ooops! Eu me enganei.')
P1 = ('voltar para a página 1', N, '1a')

# PDF -> id da página no livro (lido nas abas inferiores)
PAGE_OF_PDF = {
 1:'1a', 2:'2a', 3:'2b', 4:'3', 5:'4', 6:'5', 7:'5b', 8:'6', 9:'8', 10:'9',
 11:'9a', 12:'10a', 13:'10b', 14:'10c', 15:'10d', 16:'10e', 17:'10f',
 18:'11a', 19:'11b', 20:'11c', 21:'11d', 22:'11e', 23:'11f',
 24:'12a', 25:'12b', 26:'12c', 27:'18', 28:'lista-comida', 29:'27',
 30:'lista-video', 31:'28', 32:'lista-musica', 33:'29', 34:'30', 35:'31',
 36:'32', 37:'33', 38:'34', 39:'35', 40:'36', 41:'37', 42:'38a', 43:'38b',
 44:'38c', 45:'38d', 46:'38e', 47:'38f', 48:'39a', 49:'39b', 50:'40',
 51:'41', 52:'42', 53:'43', 54:'44', 55:'45', 56:'46', 57:'47', 58:'50', 59:'51',
}

def std(name, g, extra_side=None):
    """Página padrão: grade 4x3 + coluna lateral com volta à 1 e ooops."""
    side = {'s0': P1, 's1': OOOPS}
    if extra_side: side['s2'] = extra_side
    return {'name': name, 'g': g, 's': side}

PAGES = {
 1: {'name':'Página 1','g':{
   'r0c0':('eu',W,'eu'),'r0c1':('parar',W,'parar'),'r0c2':('mais',W,'mais'),
   'r0c3':('Mais a Dizer',N,'2a'),
   'r1c0':('você',W,'você'),'r1c1':('ajudar',W,'ajudar'),'r1c2':('acabar',W,'acabou'),
   'r1c3':('eu não sei',S,'Eu não sei.'),
   'r2c0':('Uh oh!',S,'Uh oh! Oh não!'),'r2c1':('vem',W,'vem'),'r2c2':('olhar',W,'olhar'),
   'r2c3':('Outra Coisa',N,'2a')},
  's':{'s1':OOOPS}},

 2: std('Página 2',{
   'r0c0':('é hora de',W,'é hora de'),'r0c1':('eu tenho uma pergunta',N,'8'),
   'r0c2':('eu quero fazer',N,'11a'),'r0c3':('eu gosto',N,'3'),
   'r1c0':('eu quero te contar',S,'Eu quero te contar uma coisa.'),
   'r1c1':('arrumar',W,'arrumar'),'r1c2':('vamos ir',N,'12a'),
   'r1c3':('eu não gosto disso',N,'4'),
   'r2c0':('eu tenho que ir ao banheiro',N,'50'),
   'r2c1':('eu quero te mostrar algo',N,'2b'),
   'r2c2':('fazer',N,'10a'),'r2c3':('algo está errado',N,'5')}),

 3: std('Mostrar',{
   'r0c0':('eu',W,'eu'),'r0c1':('olhe pra mim',S,'Olhe pra mim!'),
   'r0c2':('isso',W,'isso'),'r0c3':('quarto',W,'quarto'),
   'r1c0':('pegue meu comunicador',S,'Por favor, pegue meu comunicador.'),
   'r1c1':('fazer algo',W,'fazer algo'),'r1c2':('dentro',W,'dentro'),
   'r1c3':('mochila',W,'mochila'),
   'r2c0':('perguntar a alguém',N,'9'),'r2c1':('pegar',W,'pegar'),
   'r2c2':('novo',W,'novo'),'r2c3':('algum outro lugar',N,'12a')},
   ('voltar para a página 2',N,'2a')),

 4: std('Eu gosto',{
   'r0c0':('bom',W,'bom'),'r0c1':('engraçado',W,'engraçado'),
   'r0c2':('delícia',W,'delicioso'),'r0c3':('especial',W,'especial'),
   'r1c0':('ótimo',W,'ótimo'),'r1c1':('divertido',W,'divertido'),
   'r1c2':('favorito',W,'favorito'),'r1c3':('tentar',W,'tentar'),
   'r2c0':('legal',W,'legal'),'r2c1':('inteligente',W,'inteligente'),
   'r2c2':('lindo',W,'lindo'),'r2c3':('ir para lista',N,'lista')}),

 5: std('Eu não gosto',{
   'r0c0':('ruim',W,'ruim'),'r0c1':('eu não quero fazer isso',S,'Eu não quero fazer isso.'),
   'r0c2':('assustador',W,'assustador'),'r0c3':('eca',W,'eca'),
   'r1c0':('safado',W,'safado'),'r1c1':('eu não consigo',S,'Eu não consigo fazer isso.'),
   'r1c2':('entediante',W,'entediante'),'r1c3':('vamos fazer outra coisa',N,'11a'),
   'r2c0':('bobo',W,'bobo'),'r2c1':('barulhento',W,'barulhento'),
   'r2c2':('malvado',W,'malvado'),'r2c3':('ir para lista',N,'lista')}),

 6: std('Algo está errado',{
   'r0c0':('doente',N,'6'),'r0c1':('desconfortável',W,'desconfortável'),
   'r0c2':('cansado',W,'cansado'),'r0c3':('eu quero alguém',N,'9'),
   'r1c0':('machucado',N,'6'),'r1c1':('bateu',N,'6'),
   'r1c2':('bravo',W,'bravo'),'r1c3':('fique comigo',S,'Fique comigo, por favor.'),
   'r2c0':('coceira',N,'6'),'r2c1':('cortar',N,'6'),
   'r2c2':('triste',W,'triste'),'r2c3':('virar a página',N,'5b')}),

 7: std('Algo está errado 2',{
   'r0c0':('cair',W,'cair'),'r0c1':('calor',W,'calor'),
   'r0c2':('com fome',N,'18'),'r0c3':('eu não sei o que está errado',S,'Eu não sei o que está errado.'),
   'r1c0':('não quero fazer isso',S,'Eu não quero fazer isso.'),'r1c1':('frio',W,'frio'),
   'r1c2':('com sede',N,'18'),'r1c3':('eu não gosto disso',N,'4'),
   'r2c0':('quebrar',W,'quebrar'),'r2c1':('molhado',W,'molhado'),
   'r2c2':('com sono',W,'com sono'),'r2c3':('ir para lista',N,'lista')},
   ('voltar para a página 5',N,'5')),

 8: std('Partes do corpo',{
   'r0c0':('cabeça',W,'cabeça'),'r0c1':('olhos',W,'olhos'),
   'r0c2':('braço',W,'braço'),'r0c3':('barriga',W,'barriga'),
   'r1c0':('pescoço',W,'pescoço'),'r1c1':('nariz',W,'nariz'),
   'r1c2':('mão',W,'mão'),'r1c3':('costas',W,'costas'),
   'r2c0':('boca',W,'boca'),'r2c1':('orelha',W,'orelha'),
   'r2c2':('perna',W,'perna'),'r2c3':('bumbum',W,'bumbum')}),

 9: std('Perguntas',{
   'r0c0':('me diga sim ou não',S,'Você precisa me dizer sim ou não.'),
   'r0c1':('onde',W,'onde'),'r0c2':('como',W,'como'),'r0c3':('não',W,'não'),
   'r1c0':('por que',W,'por que'),'r1c1':('quando',W,'quando'),
   'r1c2':('o que está acontecendo',S,'O que está acontecendo?'),
   'r1c3':('isso ou aquilo',S,'Isso ou aquilo?'),
   'r2c0':('o que',W,'o que'),'r2c1':('quem',W,'quem'),
   'r2c2':('onde está',N,'9'),'r2c3':('onde você está indo',S,'Onde você está indo?')}),

 10: std('Pessoas',{
   'r0c0':('eu',W,'eu'),'r0c1':('Vovó Sônia',W,'Vovó Sônia'),
   'r0c2':('menino',W,'menino'),'r0c3':('amigos',N,'9a'),
   'r1c0':('Pai Kleber',W,'meu pai'),'r1c1':('Vovô Adenir',W,'Vovô Adenir'),
   'r1c2':('menina',W,'menina'),
   'r2c0':('Mãe Camila',W,'minha mãe'),'r2c1':('tio',W,'tio'),'r2c2':('tia',W,'tia'),
   'r2c3':('virar a página',N,'9a')}),

 11: std('Amigos',{
   'r0c0':('Profa Priscila',W,'Professora Priscila'),
   'r1c0':('Tia Natália',W,'Tia Natália'),'r1c1':('Tia Vivi',W,'Tia Vivi'),
   'r2c3':('outra pessoa',N,'lista')},
   ('voltar para a página 9',N,'9')),

 12: std('Ações',{
   'r0c0':('não',W,'não'),'r0c1':('pegar',W,'pegar'),'r0c2':('ir',W,'ir'),
   'r0c3':('gostar',W,'gostar'),
   'r1c0':('fazer',W,'fazer'),'r1c1':('dar',W,'dar'),'r1c2':('vir',W,'vir'),
   'r1c3':('movimentos',N,'10e'),
   'r2c0':('ver',W,'ver'),'r2c1':('falar',W,'falar'),'r2c2':('AVD',N,'10b'),
   'r2c3':('virar a página',N,'10b')}),

 13: std('Vida diária',{
   'r0c0':('não',W,'não'),'r0c1':('virar',W,'virar'),
   'r0c2':('comida e bebida',N,'18'),'r0c3':('brincar',W,'brincar'),
   'r1c0':('dormir',W,'dormir'),'r1c1':('pentear o cabelo',W,'pentear o cabelo'),
   'r1c2':('banho',W,'banho'),'r1c3':('descansar',W,'descansar'),
   'r2c0':('acordado',W,'acordado'),'r2c1':('escovar dentes',W,'escovar os dentes'),
   'r2c2':('trocar de roupa',W,'trocar de roupa'),'r2c3':('virar a página',N,'10c')},
   ('voltar para a página 10',N,'10a')),

 14: std('Ações 3',{
   'r0c0':('não',W,'não'),'r0c1':('virar',W,'virar'),'r0c2':('isso',W,'isso'),
   'r0c3':('dentro',W,'dentro'),
   'r1c0':('colocar',W,'colocar'),'r1c1':('abrir',W,'abrir'),
   'r1c2':('em cima',W,'em cima'),'r1c3':('fora',W,'fora'),
   'r2c0':('pegar',W,'pegar'),'r2c1':('fechar',W,'fechar'),
   'r2c2':('tirar',W,'tirar'),'r2c3':('virar a página',N,'10d')},
   ('voltar para a página 10',N,'10a')),

 15: std('Ações 4',{
   'r0c0':('não',W,'não'),'r0c1':('jogar',W,'jogar'),'r0c2':('lavar',W,'lavar'),
   'r0c3':('cabelo',W,'cabelo'),
   'r1c0':('querer',W,'querer'),'r1c1':('fingir',W,'fingir'),
   'r1c2':('escovar',W,'escovar'),'r1c3':('partes do corpo',N,'6'),
   'r2c0':('ter',W,'ter'),'r2c1':('fazer',W,'fazer'),
   'r2c2':('tocar',W,'tocar'),'r2c3':('ir para lista',N,'lista')},
   ('voltar para a página 10',N,'10a')),

 16: std('Movimentos',{
   'r0c0':('não',W,'não'),'r0c1':('em pé',W,'em pé'),'r0c2':('rolar',W,'rolar'),
   'r0c3':('curvar',W,'curvar'),
   'r1c0':('sentar',W,'sentar'),'r1c1':('caminhar',W,'caminhar'),
   'r1c2':('correr',W,'correr'),'r1c3':('alongar',W,'alongar'),
   'r2c0':('deitar',W,'deitar'),'r2c1':('engatinhar',W,'engatinhar'),
   'r2c2':('cair',W,'cair'),'r2c3':('virar a página',N,'10f')},
   ('voltar para a página 10',N,'10a')),

 17: std('Movimentos 2',{
   'r0c0':('não',W,'não'),'r0c1':('pegar',W,'pegar'),'r0c2':('chutar',W,'chutar'),
   'r0c3':('agarrar',W,'agarrar'),
   'r1c0':('empurrar',W,'empurrar'),'r1c1':('jogar',W,'jogar'),
   'r1c2':('pular',W,'pular'),'r1c3':('soltar',W,'soltar'),
   'r2c0':('puxar',W,'puxar'),'r2c1':('quicar',W,'quicar'),
   'r2c2':('escalar',W,'escalar'),'r2c3':('ir para lista',N,'lista')},
   ('voltar para a página 10',N,'10a')),

 18: std('Atividades',{
   'r0c0':('não',W,'não'),'r0c1':('abraçar',W,'abraçar'),
   'r0c2':('comer ou beber',N,'18'),'r0c3':('atividades externas',N,'11e'),
   'r1c0':('querer',W,'querer'),'r1c1':('descansar',W,'descansar'),
   'r1c2':('brinquedo',N,'11c'),'r1c3':('brincadeiras com água',N,'43'),
   'r2c0':('música',N,'28'),'r2c1':('assistir',N,'27'),'r2c2':('livro',N,'29'),
   'r2c3':('virar a página',N,'11b')}),

 19: std('Atividades 2',{
   'r0c0':('não',W,'não'),'r0c1':('desenhar',N,'28'),
   'r0c2':('Tablet',N,'47'),'r0c3':('eu quero alguém',N,'9'),
   'r1c0':('fazer',N,'11d'),'r1c1':('jogo',N,'30'),
   'r1c3':('quero fazer o que os outros estão fazendo',S,'Eu quero fazer o que os outros estão fazendo.'),
   'r2c0':('jogar',W,'jogar'),'r2c1':('fantasia',N,'44'),
   'r2c3':('ir para lista',N,'lista')},
   ('voltar para a página 11',N,'11a')),

 20: std('Brinquedos',{
   'r0c0':('não',W,'não'),'r0c1':('blocos',N,'36'),'r0c2':('bonecos',N,'38a'),
   'r0c3':('bola',N,'41'),
   'r1c0':('ter',W,'ter'),'r1c1':('quebra cabeça',N,'37'),
   'r1c2':('carrinhos',N,'39a'),'r1c3':('piscina de bolinhas',N,'46'),
   'r2c0':('jogar',W,'jogar'),'r2c1':('bolinha de sabão',N,'40'),
   'r2c2':('brinquedos sonoros',N,'28'),'r2c3':('ir para lista',N,'lista')},
   ('voltar para a página 11',N,'11a')),

 21: std('Fazer',{
   'r0c0':('não',W,'não'),'r0c1':('desenhar',N,'32'),'r0c2':('massinha',N,'31'),
   'r0c3':('desenho, quadro',W,'desenho'),
   'r1c0':('querer',W,'querer'),'r1c1':('pintar',N,'33'),
   'r1c2':('construir',N,'42'),'r1c3':('brincadeiras sensoriais',N,'45'),
   'r2c0':('fazer',N,'11d'),'r2c1':('cortar e colar',N,'34'),
   'r2c2':('cozinhar',N,'35'),'r2c3':('ir para lista',N,'lista')},
   ('voltar para a página 11',N,'11a')),

 22: std('Atividades externas',{
   'r0c0':('não',W,'não'),'r0c1':('nadar',W,'nadar'),'r0c2':('piscina',W,'piscina'),
   'r0c3':('bola',N,'41'),
   'r1c0':('ir',W,'ir'),'r1c1':('cavar',W,'cavar'),'r1c2':('jardim',W,'jardim'),
   'r1c3':('brincadeiras com água',N,'43'),
   'r2c0':('caminhar',W,'caminhar'),'r2c1':('motocicleta',W,'motocicleta'),
   'r2c2':('bicicleta',W,'bicicleta'),'r2c3':('virar a página',N,'11f')},
   ('voltar para a página 11',N,'11a')),

 23: std('Parquinho',{
   'r0c0':('não',W,'não'),'r0c1':('cama elástica',W,'cama elástica'),
   'r0c2':('caixa de areia',W,'caixa de areia'),'r0c3':('parquinho',W,'parquinho'),
   'r1c0':('ir',W,'ir'),'r1c1':('balançar',W,'balançar'),
   'r1c2':('trepa trepa',W,'trepa trepa'),'r1c3':('praça',W,'praça'),
   'r2c1':('escorregador',W,'escorregador'),'r2c2':('gangorra',W,'gangorra'),
   'r2c3':('ir para lista',N,'lista')},
   ('voltar para a página 11',N,'11a')),

 24: std('Lugares',{
   'r0c0':('não',W,'não'),'r0c1':('casa',W,'casa'),
   'r0c2':('Escola Criativa',W,'Escola Criativa'),'r0c3':('atividades externas',N,'11e'),
   'r1c0':('ir',W,'ir'),'r1c1':('dar uma volta',W,'dar uma volta de carro'),
   'r1c2':('casa da vovó',W,'casa da vovó'),'r1c3':('algum lugar na casa',N,'12c'),
   'r2c0':('visitar',N,'9'),'r2c1':('no carro',W,'no carro'),
   'r2c2':('restaurante',W,'restaurante'),'r2c3':('virar a página',N,'12b')}),

 25: std('Lugares 2',{
   'r0c0':('biblioteca',W,'biblioteca'),'r0c1':('médicos',W,'médicos'),
   'r0c2':('piscina',W,'piscina'),'r0c3':('parquinho',N,'11f'),
   'r1c0':('Ludens',W,'Ludens'),'r1c1':('Clínica Conduz',W,'Clínica Conduz'),
   'r1c2':('Comunicare',W,'Comunicare'),'r1c3':('praça',W,'praça'),
   'r2c0':('shopping',W,'shopping'),'r2c1':('praia',W,'praia'),
   'r2c2':('zoológico',W,'zoológico'),'r2c3':('ir para lista',N,'lista')},
   ('voltar para a página 12',N,'12a')),

 26: std('Na casa',{
   'r0c0':('ir',W,'ir'),'r0c1':('porta',W,'porta'),'r0c2':('cozinha',W,'cozinha'),
   'r0c3':('cama',W,'cama'),
   'r1c0':('banheiro',W,'banheiro'),'r1c1':('janela',W,'janela'),
   'r1c2':('sala',W,'sala'),'r1c3':('quarto',W,'quarto'),
   'r2c0':('chão',W,'chão'),'r2c1':('lavanderia',W,'lavanderia'),
   'r2c2':('mesa',W,'mesa'),'r2c3':('ir para lista',N,'lista')},
   ('voltar para a página 12',N,'12a')),

 27: std('Comida e bebida',{
   'r0c0':('o que',W,'o que'),'r0c1':('comer',W,'comer'),'r0c2':('mais',W,'mais'),
   'r0c3':('comida',N,'lista-comida'),
   'r1c0':('eu',W,'eu'),'r1c1':('ajudar',W,'ajudar'),'r1c2':('acabar',W,'acabou'),
   'r1c3':('bebida',N,'lista-comida'),
   'r2c0':('espere um minuto',S,'Espere um minuto.'),'r2c1':('eca',W,'eca'),
   'r2c2':('gostoso',W,'gostoso'),'r2c3':('outro, diferente',W,'outro')}),

 29: std('TV',{
   'r0c0':('o que está passando',S,'O que está passando?'),
   'r0c1':('aumentar o volume',S,'Aumenta o volume.'),
   'r0c2':('trocar de canal',S,'Troca de canal.'),'r0c3':('eu gosto',N,'3'),
   'r1c0':('eu',W,'eu'),'r1c1':('abaixar o volume',S,'Abaixa o volume.'),
   'r1c2':('programa',N,'lista-video'),'r1c3':('eu não gosto disso',N,'4'),
   'r2c0':('assistir',W,'assistir'),'r2c1':('desligar',S,'Desliga.'),
   'r2c2':('vídeo do YouTube',N,'lista-video'),'r2c3':('TV',W,'televisão')}),

 31: std('Música',{
   'r0c0':('o que',W,'o que'),'r0c1':('tocar',W,'tocar'),
   'r0c2':('aumentar o volume',S,'Aumenta o volume.'),'r0c3':('cantar',N,'lista-musica'),
   'r1c0':('eu',W,'eu'),'r1c1':('ouvir',W,'ouvir'),
   'r1c2':('abaixar o volume',S,'Abaixa o volume.'),'r1c3':('instrumentos',N,'lista-musica'),
   'r2c0':('você',W,'você'),'r2c1':('desligar',S,'Desliga.'),
   'r2c2':('dançar',W,'dançar'),'r2c3':('brinquedos sonoros',N,'lista-musica')}),

 33: std('Livro',{
   'r0c0':('o que',W,'o que'),'r0c1':('levantar a aba',W,'levantar a aba'),
   'r0c2':('de novo',W,'de novo'),'r0c3':('eu gosto disso',N,'3'),
   'r1c0':('eu',W,'eu'),'r1c1':('vamos fingir',S,'Vamos fingir!'),
   'r1c2':('outro, diferente',W,'outro'),'r1c3':('eu não gosto disso',N,'4'),
   'r2c0':('ler',W,'ler'),'r2c1':('livro',N,'lista'),
   'r2c2':('desenho, quadro',W,'desenho'),'r2c3':('virar a página',N,'30')}),

 34: std('Jogo',{
   'r0c0':('quem',W,'quem'),'r0c1':('não',W,'não'),'r0c2':('de novo',W,'de novo'),
   'r0c3':('boa jogada',S,'Boa jogada!'),
   'r1c0':('eu',W,'eu'),'r1c1':('virar',W,'virar'),'r1c2':('vencer',W,'vencer'),
   'r1c3':('escolher',W,'escolher'),
   'r2c0':('você',W,'você'),'r2c1':('jogar',W,'jogar'),
   'r2c2':('trapacear',W,'trapacear'),'r2c3':('jogo',W,'jogo')}),

 35: std('Massinha',{
   'r0c0':('o que',W,'o que'),'r0c1':('esticar',W,'esticar'),'r0c2':('mais',W,'mais'),
   'r0c3':('massinha',W,'massinha'),
   'r1c0':('eu',W,'eu'),'r1c1':('modelar',W,'modelar'),'r1c2':('acabou',W,'acabou'),
   'r1c3':('forminha',W,'forminha'),
   'r2c0':('não',W,'não'),'r2c1':('apertar',W,'apertar'),
   'r2c2':('cortar',W,'cortar'),'r2c3':('fazer',N,'lista')}),

 36: std('Desenhar',{
   'r0c0':('o que',W,'o que'),'r0c1':('precisar',W,'precisar'),'r0c2':('mais',W,'mais'),
   'r0c3':('papel',W,'papel'),
   'r1c0':('eu',W,'eu'),'r1c1':('desenhar',W,'desenhar'),'r1c2':('acabar',W,'acabou'),
   'r1c3':('desenho, quadro',W,'desenho'),
   'r2c0':('você',W,'você'),'r2c1':('diferente, outro',W,'outro'),
   'r2c2':('cores',W,'cores'),'r2c3':('giz, lápis',W,'lápis')}),

 37: std('Pintar',{
   'r0c0':('o que',W,'o que'),'r0c1':('precisar',W,'precisar'),'r0c2':('mais',W,'mais'),
   'r0c3':('papel',W,'papel'),
   'r1c0':('eu',W,'eu'),'r1c1':('pintar',W,'pintar'),'r1c2':('acabar',W,'acabou'),
   'r1c3':('dedo, mão',W,'mão'),
   'r2c0':('lavar',W,'lavar'),'r2c1':('diferente, outro',W,'outro'),
   'r2c2':('cores',W,'cores'),'r2c3':('pincel',W,'pincel')}),

 38: std('Cortar e colar',{
   'r0c0':('eu',W,'eu'),'r0c1':('precisar',W,'precisar'),'r0c2':('mais',W,'mais'),
   'r0c3':('papel',W,'papel'),
   'r1c0':('virar',W,'virar do outro lado'),'r1c1':('ajudar',W,'ajudar'),
   'r1c2':('acabou',W,'acabou'),'r1c3':('cola',W,'cola'),
   'r2c0':('lavar',W,'lavar'),'r2c1':('grudar',W,'grudar'),
   'r2c2':('cor',W,'cor'),'r2c3':('tesoura',W,'tesoura')}),

 39: std('Cozinhar',{
   'r0c0':('o que',W,'o que'),'r0c1':('querer',W,'querer'),'r0c2':('mais',W,'mais'),
   'r0c3':('cozinhar',W,'cozinhar'),
   'r1c0':('está bom',S,'Está bom?'),'r1c1':('ajudar',W,'ajudar'),
   'r1c2':('mexer, misturar',W,'misturar'),'r1c3':('gostoso',W,'gostoso'),
   'r2c0':('eu',W,'eu'),'r2c1':('provar',W,'provar'),
   'r2c2':('cortar, pedaço',W,'cortar'),'r2c3':('eca',W,'eca')}),

 40: std('Blocos',{
   'r0c0':('eu',W,'eu'),'r0c1':('construir',W,'construir'),'r0c2':('mais',W,'mais'),
   'r0c3':('blocos',W,'blocos'),
   'r1c0':('não',W,'não'),'r1c1':('colocar',W,'colocar'),'r1c2':('acabar',W,'acabou'),
   'r1c3':('torre',W,'torre'),
   'r2c0':('Uh oh!',S,'Uh oh! Oh não!'),'r2c1':('derrubar',W,'derrubar'),
   'r2c2':('alta',W,'alta'),'r2c3':('outra',N,'lista')}),

 41: std('Quebra-cabeça',{
   'r0c0':('onde',W,'onde'),'r0c1':('precisar',W,'precisar'),
   'r0c2':('isso! muito bem',S,'Isso! Muito bem!'),'r0c3':('quebra cabeça',W,'quebra-cabeça'),
   'r1c0':('eu',W,'eu'),'r1c1':('colocar',W,'colocar'),'r1c2':('acabou',W,'acabou'),
   'r1c3':('peça',W,'peça'),
   'r2c0':('não',W,'não'),'r2c1':('virar',W,'virar'),
   'r2c2':('encaixar',W,'encaixar'),'r2c3':('diferente, outro',W,'outro')}),

 42: std('Bonecos',{
   'r0c0':('o que',W,'o que'),'r0c1':('querer',W,'querer'),
   'r0c2':('alimentar',N,'38b'),'r0c3':('bonecos',N,'lista'),
   'r1c0':('eu',W,'eu'),'r1c1':('ir',W,'ir'),'r1c2':('vestir',N,'38c'),
   'r1c3':('trocar fralda',N,'38e'),
   'r2c0':('não',W,'não'),'r2c1':('abraço',W,'abraço'),
   'r2c2':('dar banho',N,'38d'),'r2c3':('cama',N,'38f')}),

 43: std('Alimentar a boneca',{
   'r0c0':('eu',W,'eu'),'r0c1':('alimentar',W,'alimentar'),'r0c2':('mais',W,'mais'),
   'r0c3':('boneco',W,'boneco'),
   'r1c0':('não',W,'não'),'r1c1':('delícia, gostoso',W,'gostoso'),
   'r1c2':('acabar',W,'acabou'),'r1c3':('bebidas',W,'bebida'),
   'r2c0':('querer',W,'querer'),'r2c1':('eca',W,'eca'),
   'r2c2':('comida',W,'comida'),'r2c3':('tigela e colher',W,'tigela e colher')},
   ('voltar para a página 38',N,'38a')),

 44: std('Vestir a boneca',{
   'r0c0':('eu',W,'eu'),'r0c1':('colocar, vestir',W,'vestir'),'r0c2':('mais',W,'mais'),
   'r0c3':('boneco',W,'boneco'),
   'r1c0':('não',W,'não'),'r1c1':('tirar',W,'tirar'),'r1c2':('acabou',W,'acabou'),
   'r1c3':('pentear o cabelo',W,'pentear o cabelo'),
   'r2c0':('ajudar',W,'ajudar'),'r2c1':('escolher',W,'escolher'),
   'r2c2':('lindo',W,'lindo'),'r2c3':('roupas',W,'roupas')},
   ('voltar para a página 38',N,'38a')),

 45: std('Banho da boneca',{
   'r0c0':('eu',W,'eu'),'r0c1':('lavar',W,'lavar'),'r0c2':('mais',W,'mais'),
   'r0c3':('boneco',W,'boneco'),
   'r1c0':('não',W,'não'),'r1c1':('molhar',W,'molhado'),
   'r1c2':('sair da banheira',S,'Sair da banheira.'),'r1c3':('banheira',W,'banheira'),
   'r2c0':('espirrar',W,'espirrar'),'r2c1':('secar',W,'secar'),
   'r2c2':('sabonete',W,'sabonete'),'r2c3':('água',W,'água')},
   ('voltar para a página 38',N,'38a')),

 46: std('Fralda da boneca',{
   'r0c0':('eu',W,'eu'),'r0c1':('limpo',W,'limpo'),'r0c2':('mais',W,'mais'),
   'r0c3':('boneco',W,'boneco'),
   'r1c0':('secar',W,'secar'),'r1c1':('xixi',W,'xixi'),'r1c2':('acabou',W,'acabou'),
   'r1c3':('bumbum',W,'bumbum'),
   'r2c0':('fedido',W,'fedido'),'r2c1':('cocô',W,'cocô'),
   'r2c2':('talco',W,'talco'),'r2c3':('fralda',W,'fralda')},
   ('voltar para a página 38',N,'38a')),

 47: std('Cama da boneca',{
   'r0c0':('tempo, hora',W,'hora'),'r0c1':('boa noite',S,'Boa noite!'),
   'r0c2':('mais',W,'mais'),'r0c3':('boneco',W,'boneco'),
   'r1c0':('dormir',W,'dormir'),'r1c1':('arrumar a cama',W,'arrumar a cama'),
   'r1c2':('beijos e abraços',W,'beijos e abraços'),'r1c3':('ursinho',W,'ursinho'),
   'r2c0':('acordar',W,'acordar'),'r2c1':('balançar',W,'balançar'),
   'r2c2':('cantar, música',W,'cantar'),'r2c3':('berço',W,'berço')},
   ('voltar para a página 38',N,'38a')),

 48: std('Carrinhos',{
   'r0c0':('onde',W,'onde'),'r0c1':('empurrar',W,'empurrar'),
   'r0c2':('de novo',W,'de novo'),'r0c3':('rua, estrada',W,'rua'),
   'r1c0':('ir',W,'ir'),'r1c1':('rápido',W,'rápido'),'r1c2':('acidente',W,'acidente'),
   'r1c3':('ponte',W,'ponte'),
   'r2c0':('Uh oh!',S,'Uh oh! Oh não!'),'r2c1':('devagar',W,'devagar'),
   'r2c2':('carro',W,'carro'),'r2c3':('virar a página',N,'39b')}),

 49: std('Carrinhos 2',{
   'r0c0':('querer',W,'querer'),'r0c1':('mapa',W,'mapa'),
   'r0c2':('carro de polícia',W,'carro de polícia'),'r0c3':('ônibus',W,'ônibus'),
   'r1c0':('sirene',W,'sirene'),'r1c1':('garagem',W,'garagem'),
   'r1c2':('caminhão de bombeiro',W,'caminhão de bombeiro'),'r1c3':('caminhão',W,'caminhão'),
   'r2c0':('buzina',W,'buzina'),'r2c1':('motocicleta',W,'motocicleta'),
   'r2c2':('ambulância',W,'ambulância'),'r2c3':('ir para a lista',N,'lista')},
   ('voltar para a página 39',N,'39a')),

 50: std('Bolinha de sabão',{
   'r0c0':('eu',W,'eu'),'r0c1':('assoprar',W,'assoprar'),'r0c2':('mais',W,'mais'),
   'r0c3':('grande',W,'grande'),
   'r1c0':('você',W,'você'),'r1c1':('estourar',W,'estourar'),
   'r1c2':('acabar',W,'acabou'),'r1c3':('pequeno',W,'pequeno'),
   'r2c0':('Uh oh!',S,'Uh oh! Oh não!'),'r2c1':('uau!',S,'Uau!'),
   'r2c2':('muitos',W,'muitos'),'r2c3':('bolinha de sabão',W,'bolinha de sabão')}),

 51: std('Bola',{
   'r0c0':('onde',W,'onde'),'r0c1':('dar',W,'dar'),'r0c2':('jogar',W,'jogar'),
   'r0c3':('fazer de novo',W,'de novo'),
   'r1c0':('eu',W,'eu'),'r1c1':('rolar',W,'rolar'),'r1c2':('pegar',W,'pegar'),
   'r1c3':('acabou',W,'acabou'),
   'r2c0':('você',W,'você'),'r2c1':('quicar',W,'quicar'),
   'r2c2':('chutar',W,'chutar'),'r2c3':('bola',W,'bola')}),

 52: std('Ferramentas',{
   'r0c0':('o que',W,'o que'),'r0c1':('construir',W,'construir'),
   'r0c2':('prego',W,'prego'),'r0c3':('madeira',W,'madeira'),
   'r1c0':('eu',W,'eu'),'r1c1':('martelo',W,'martelo'),
   'r1c2':('chave de fenda',W,'chave de fenda'),'r1c3':('caixa de ferramentas',W,'caixa de ferramentas'),
   'r2c0':('precisar',W,'precisar'),'r2c1':('serrar, serra',W,'serra'),
   'r2c2':('furadeira',W,'furadeira'),'r2c3':('ferramentas',N,'lista')}),

 53: std('Brincadeira de água',{
   'r0c0':('eu',W,'eu'),'r0c1':('espirrar água',W,'espirrar água'),
   'r0c2':('mais',W,'mais'),'r0c3':('água',W,'água'),
   'r1c0':('não',W,'não'),'r1c1':('despejar',W,'despejar'),
   'r1c2':('acabar',W,'acabou'),'r1c3':('barco',W,'barco'),
   'r2c0':('Uh oh!',S,'Uh oh! Oh não!'),'r2c1':('molhado',W,'molhado'),
   'r2c2':('secar',W,'secar'),'r2c3':('brinquedos',N,'lista')}),

 54: std('Fantasia',{
   'r0c0':('o que',W,'o que'),'r0c1':('vestir',W,'vestir'),'r0c2':('mais',W,'mais'),
   'r0c3':('chapéu',W,'chapéu'),
   'r1c0':('eu',W,'eu'),'r1c1':('tirar',W,'tirar'),
   'r1c2':('estou pronto',S,'Estou pronto!'),'r1c3':('jóias',N,'lista'),
   'r2c0':('fingir',W,'fingir'),'r2c1':('olhar no espelho',W,'olhar no espelho'),
   'r2c2':('roupa',N,'lista'),'r2c3':('fantasia de personagem',N,'lista')}),

 55: std('Fazer bagunça',{
   'r0c0':('eu',W,'eu'),'r0c1':('sentir, tocar',W,'tocar'),'r0c2':('mais',W,'mais'),
   'r0c3':('eu gosto disso',N,'3'),
   'r1c0':('não',W,'não'),'r1c1':('pegajoso',W,'pegajoso'),
   'r1c2':('acabar',W,'acabou'),'r1c3':('eu não gosto disso',N,'4'),
   'r2c0':('lavar',W,'lavar'),'r2c1':('bagunçado',W,'bagunçado'),
   'r2c2':('mão',W,'mão'),'r2c3':('ir para lista',N,'lista')}),

 56: std('Piscina de bolinhas',{
   'r0c0':('eu',W,'eu'),'r0c1':('jogar',W,'jogar'),'r0c2':('mais',W,'mais'),
   'r0c3':('eu gosto disso',N,'3'),
   'r1c0':('você',W,'você'),'r1c1':('pegar',W,'pegar'),'r1c2':('bolinha',W,'bolinha'),
   'r1c3':('eu não gosto disso',N,'4'),
   'r2c0':('Uh oh!',S,'Uh oh! Oh não!'),'r2c1':('arrumar',W,'arrumar'),
   'r2c2':('brincar na piscina',W,'brincar na piscina'),
   'r2c3':('deitar na piscina',W,'deitar na piscina')}),

 57: std('Computador',{
   'r0c0':('o que',W,'o que'),'r0c1':('ajuda',W,'ajuda'),
   'r0c2':('fazer de novo',W,'de novo'),'r0c3':('cantar',W,'cantar'),
   'r1c0':('eu',W,'eu'),'r1c1':('espere, pare',W,'espere'),
   'r1c2':('acabou',W,'acabou'),'r1c3':('livro',N,'lista'),
   'r2c0':('você',W,'você'),'r2c1':('escolher',W,'escolher'),
   'r2c2':('diferente, outro',W,'outro'),'r2c3':('jogo, programa',N,'lista')}),

 58: std('Banheiro',{
   'r0c0':('eu',W,'eu'),'r0c1':('não consigo fazer',S,'Eu não consigo fazer.'),
   'r0c2':('mais',W,'mais'),'r0c3':('vaso sanitário',W,'vaso sanitário'),
   'r1c0':('sentar',W,'sentar'),'r1c1':('fazer cocô',W,'fazer cocô'),
   'r1c2':('acabar',W,'acabou'),'r1c3':('cueca',W,'cueca'),
   'r2c0':('limpar o bumbum',W,'limpar o bumbum'),'r2c1':('fazer xixi',W,'fazer xixi'),
   'r2c2':('descarga',W,'descarga'),'r2c3':('papel higiênico',W,'papel higiênico')}),

 59: std('Fralda',{
   'r0c0':('eu',W,'eu'),'r0c1':('trocar',W,'trocar'),'r0c2':('acabar',W,'acabou'),
   'r0c3':('fralda',W,'fralda'),
   'r1c0':('secar',W,'secar'),'r1c1':('xixi',W,'xixi'),'r1c2':('limpo',W,'limpo'),
   'r1c3':('bumbum',W,'bumbum'),
   'r2c0':('Uh oh!',S,'Uh oh! Oh não!'),'r2c1':('cocô',W,'cocô'),
   'r2c2':('deitar',W,'deitar'),'r2c3':('pomada',W,'pomada')}),
}
