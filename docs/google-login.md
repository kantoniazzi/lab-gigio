# Login com Google — configuração

## Os quatro client IDs, e por que são quatro

Confunde, então vale a tabela. Todos começam com o mesmo número de projeto
(`417402288301-`); o que os diferencia é o **tipo**, não o número.

| Tipo | Para que serve | Vai no código? |
|---|---|---|
| **iOS** | Login no iPad | Sim, como `clientId` |
| **Android** (release) | O Google valida por pacote + SHA-1 | **Não** |
| **Android** (debug) | Idem, para builds de `flutter run` | **Não** |
| **Aplicativo da Web** | O `serverClientId` exigido no Android | Sim, como `serverClientId` |

O client ID de Android **não é uma credencial que o app carrega** — ele só
registra que "o pacote `com.antoniazi.gigio`, assinado com aquele SHA-1, tem
permissão". Por isso não aparece em nenhum `--dart-define`.

O `serverClientId` identifica quem *recebe* o token de identidade. Como o
Credential Manager do Android foi desenhado para fluxos com servidor, ele exige
um client ID de Web — mesmo aqui, onde não há servidor nenhum.

## A chave secreta do cliente Web

**Não é usada e não deve entrar no app.** Ela serve para trocar código por token
no lado do servidor, e o Gigio não tem servidor. Se ela vazar, pode ser
redefinida no console sem afetar o aplicativo.

## SHA-1 registrados

```
release: F0:EB:CF:9F:80:68:4D:75:92:6D:4F:4A:34:25:9C:A5:9D:54:42:2B
debug:   D5:95:D4:38:99:32:E7:E5:DF:2D:53:A6:71:C4:80:73:C4:F5:D5:87
```

O de release vem de `~/.gigio-keys/upload.jks`; o de debug, de
`~/.android/debug.keystore`.

## Usuários de teste

A tela de consentimento está em modo **Teste**, então **só contas listadas como
testadoras conseguem entrar**. Adicionar em Google Auth Platform → Público. Se
o login falhar com "acesso bloqueado", é isto.

## Compilar

```bash
flutter build apk --release \
  --dart-define=GIGIO_GOOGLE_CLIENT_ID=<iOS client id> \
  --dart-define=GIGIO_GOOGLE_SERVER_CLIENT_ID=<Web client id> \
  --dart-define=GIGIO_DD_CLIENT_TOKEN=pub... \
  --dart-define=GIGIO_DD_APP_ID=... \
  --dart-define=GIGIO_DD_ENV=prod
```

Sem o valor que a plataforma exige — `serverClientId` no Android, `clientId` nas
outras — o app **abre direto no board**, sem tela de login. Uma build mal
configurada não pode prender a criança numa tela sem saída.
