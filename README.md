# PULSE

Aplicativo Android de treinos, acompanhamento de progresso e assistência
inteligente. O núcleo funciona sem conta e mantém os dados principais no
aparelho.

## Funcionalidades

- onboarding e personalização de preferências;
- catálogo de exercícios com demonstrações visuais;
- criação, importação, exportação e compartilhamento de fichas;
- leitura e geração de QR Codes de treino;
- execução de treino com séries, cargas, descanso e histórico;
- medidas corporais, calendário, métricas e evolução;
- backup local iniciado pelo usuário;
- bloqueio opcional com a biometria ou credencial do Android;
- Assistente PULSE com análise local e resposta online opcional.

## Tecnologia e arquitetura

- Flutter e Dart;
- Riverpod para estado e injeção de dependências;
- SQLite e SharedPreferences para persistência local;
- organização gradual por `features/` com camadas de domínio, dados e
  apresentação;
- Android 7.0 ou posterior (`minSdk 24`), com alvo Android 16 (`targetSdk 36`).

O Assistente online envia somente o contexto técnico necessário por HTTPS para
um Cloudflare Worker protegido, que consulta o Google Gemini. Métricas de
progresso permanecem no aparelho. Quando a rede, a cota ou o serviço não estão
disponíveis, o app usa a análise local. Consulte a
[política de privacidade](https://julianocarvalho1.github.io/pulse-app/politica-de-privacidade/).

## Preparar o ambiente

Requisitos:

- Flutter estável compatível com Dart 3.12;
- Android Studio e Android SDK 36;
- JDK 17.

```powershell
flutter pub get
flutter run
```

## Qualidade

Execute toda a validação local gratuita com:

```powershell
.\tool\validate_release.ps1
```

O comando verifica formatação, análise estática, testes e o build do APK de
depuração. O mesmo conjunto roda no GitHub Actions.

## Gerar o AAB da Google Play

1. Confirme que não existem itens `PENDENTE` no inventário em
   `docs/google-play/inventario-licencas-midias.csv`.
2. Restaure a chave de upload existente no diretório `android/` e configure
   `android/key.properties` a partir de `android/key.properties.example`. Não
   gere outra chave para um app que já teve uma versão assinada.
3. Guarde a chave, o arquivo `key.properties` e a senha em pelo menos duas
   cópias privadas. Eles não são versionados pelo Git.
4. Gere e verifique o pacote assinado:

   ```powershell
   .\tool\validate_release.ps1 -BuildAppBundle
   ```

O arquivo final será criado em
`build/app/outputs/bundle/release/app-release.aab`.

Antes do envio, siga `docs/google-play/CHECKLIST_LANCAMENTO.md`. A taxa única de
cadastro da Google Play, quando ainda não há conta de desenvolvedor, é um custo
externo inevitável; desenvolvimento, testes e os recursos principais do PULSE
não dependem de ferramenta paga.

## Privacidade e segurança

- não há anúncios nem SDK de analytics;
- o app não exige cadastro;
- backup automático do Android está desativado;
- câmera é solicitada somente para leitura de QR Code, após explicação no app;
- credenciais de assinatura e arquivos locais do Android são ignorados pelo Git;
- o Assistente não substitui orientação médica ou profissional.

## Situação de lançamento

A preparação técnica está documentada em `docs/google-play/`. Os bloqueios que
dependem do responsável pelo app são: guardar a chave de upload com segurança,
publicar a política de privacidade atualizada e concluir as declarações e os
testes exigidos pela Play Console. A licença das mídias do RepDB, a proteção de
cota, a retenção do backend e o relato interno da IA já estão documentados e
implementados.

## Licença

Não há licença de código aberto definida. Apesar de o repositório ser público,
isso não concede automaticamente permissão para reutilizar o código ou as
mídias. A procedência de cada ativo deve ser registrada antes da publicação.

Os dados e as imagens de exercícios do RepDB seguem a licença específica em
`third_party/repdb/LICENSE-DATA.md` e exigem atribuição visível. Consulte
`docs/exercise-data-sources.md`.
