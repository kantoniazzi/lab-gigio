# Distribuição do Gigio

Controle de quem instala fica **nas lojas**, não em backend próprio. Para o
estágio atual isso resolve o problema com zero código, zero custo de servidor e
zero obrigação de conformidade adicional — e acaba com a expiração de 7 dias.

## Princípio inegociável

**O app nunca pode emudecer.** Se um dia entrar licenciamento próprio, ele pode
bloquear edição, sincronização e novas instalações — mas jamais a fala. Uma
falha de rede ou um clique errado num painel não podem tirar a voz de uma
criança. Ver o anexo de observabilidade no plano.

## iOS — TestFlight

**Pré-requisito:** conta paga do Apple Developer Program (US$ 99/ano). A conta
gratuita atual (Personal Team) não publica no TestFlight e expira em 7 dias.

1. Inscrever-se em <https://developer.apple.com/programs/>
2. Em App Store Connect, criar o app com o bundle `com.antoniazi.gigio`
3. No Xcode: Product → Archive → Distribute App → TestFlight
4. Convidar por e-mail em TestFlight → Testers

- **Teste interno:** até 100 pessoas da equipe, sem revisão da Apple, disponível
  em minutos.
- **Teste externo:** até 10 mil pessoas, exige Beta App Review (~1 a 2 dias na
  primeira submissão).

Remover alguém da lista revoga o acesso à próxima atualização.

## Android — teste fechado na Play

**Pré-requisito:** conta do Google Play Console (US$ 25, pagamento único).

1. Criar o app no Play Console
2. Enviar `build/app/outputs/bundle/release/app-release.aab`
3. Testing → Closed testing → criar lista de e-mails
4. Compartilhar o link de adesão

Para instalação direta, sem loja, o APK assinado também serve:
`build/app/outputs/flutter-apk/app-release.apk`

## ⚠️ A chave de assinatura Android

Fica em `~/.gigio-keys/` — **fora do repositório, de propósito**, e ignorada
pelo git.

```
~/.gigio-keys/upload.jks        chave (RSA 4096, válida até 2054)
~/.gigio-keys/key.properties    senhas
```

**Faça backup dos dois agora, num gerenciador de senhas ou cofre.**

Perder essa chave significa **nunca mais conseguir publicar atualização** do app
na Play Store sob o mesmo pacote. Não há recuperação: seria preciso publicar um
app novo, perdendo instalações e avaliações. Vazá-la permite que terceiros
assinem pacotes se passando pelo seu app.

## Conformidade antes de publicar

- [ ] Política de privacidade publicada (obrigatória nas duas lojas)
- [ ] Rótulos de privacidade da App Store — o Gigio **não coleta nada**, o que
      torna o preenchimento trivial e é um diferencial de venda
- [ ] Play Data Safety — idem
- [ ] Classificação indicativa
- [ ] **Licenciamento de PCS e PODD** antes de qualquer versão comercial. O
      conteúdo atual é material da própria família, para uso pessoal. Ver
      `assets/podd/LEIA-ME.txt`
- [ ] Verificar o nome "Gigio" no INPI

## Instalar no iPad preservando os dados

O `flutter install` **desinstala antes**, o que apaga o board personalizado pelo
cuidador. Para atualizar preservando:

```bash
xcrun devicectl device install app --device <UDID> build/ios/iphoneos/Runner.app
```

## Estado atual dos artefatos

| Artefato | Tamanho | Assinatura |
|---|---|---|
| `app-release.aab` | 104 MB | chave de upload |
| `app-release.apk` | 106 MB | chave de upload |
| `Runner.app` (iOS) | 72 MB | Personal Team (expira em 7 dias) |

Auditado: nenhuma permissão `INTERNET` no pacote final.
