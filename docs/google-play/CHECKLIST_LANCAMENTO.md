# Checklist de lançamento do PULSE

Atualizado em 9 de agosto de 2026. Um item marcado como concluído foi verificado
no código ou no ambiente local; não significa aprovação da Google Play.

## Bloqueios antes do primeiro envio

- [x] Substituir o ícone Canva por arte original criada para o PULSE e registrar
  a origem no `inventario-licencas-midias.csv`.
- [x] Remover os GIFs sem origem comprovada e substituí-los por 200 WebP do
  RepDB Free Tier, com licença comercial, evidência e atribuição visível.
- [x] Implantar no Worker gratuito o relato de problema em conteúdo gerado por
  IA, vinculado à resposta original. Ver `DECISAO_IA.md`.
- [x] Reduzir a amostragem dos logs persistentes do Worker de 100% para 5%.
- [x] Localizar a chave de upload já usada na atualização anterior e confirmar
  na Play Console as impressões digitais do certificado de upload: SHA-1
  `A9:82:C3:28:76:7D:FE:75:07:CC:3A:FD:6A:A6:20:C9:8D:45:97:A7` e SHA-256
  `BF:89:C2:B0:FE:A3:A9:F4:47:18:DA:DE:58:82:9C:7F:F9:4A:DC:B8:68:02:F9:64:A3:2A:D3:54:67:B8:AA:4E`.
- [x] Conta de desenvolvedor criada e taxa única de US$ 25 paga.
- [ ] Aguardar a resposta do chamado `9-5259000041100` sobre a conta pessoal e
  a classificação do PULSE. Não abrir MEI nem declarar categoria falsa antes
  da orientação escrita da Google Play.
- [ ] Concluir o teste fechado com pelo menos 12 participantes inscritos por 14
  dias contínuos antes de pedir acesso à produção. Em 9 de agosto de 2026, a
  Play Console confirmou 12 testadores contínuos há 4 dias.
- [x] Testar em pelo menos um celular Android físico, especialmente câmera,
  biometria, seleção de arquivos, compartilhamento e retomada de treino.

## Engenharia Android

- [x] `applicationId` definitivo: `com.julianocarvalho.pulse`.
- [x] `versionCode` 1 já usado no teste fechado; próximo pacote configurado como
  `1.0.0+2` (`versionCode` 2).
- [x] `minSdk 24`, `compileSdk 36` e `targetSdk 36`.
- [x] APK de depuração compila.
- [x] Formatação, análise estática e suíte automatizada aprovadas.
- [x] APK aprovado por `zipalign -c -P 16 4` para alinhamento de 16 KB.
- [x] Falha do CI causada por assinatura ausente corrigida localmente.
- [x] Câmera declarada como recurso opcional; aparelhos sem câmera não ficam
  excluídos da loja.
- [x] Tráfego HTTP sem criptografia bloqueado.
- [x] Backup automático do Android desativado para evitar cópia involuntária de
  dados locais.
- [x] Credenciais `.jks`, `.keystore` e `key.properties` ignoradas pelo Git.
- [x] Gerar o AAB `1.0.0+2` assinado com
  `tool/validate_release.ps1 -BuildAppBundle`. Arquivo local verificado com
  83.020.488 bytes e SHA-256
  `8B5244C7F9773A3C269037DA3C473D3084D0EE505401FF647FB3D907FAD5060C`.
- [ ] Enviar primeiro à faixa de teste interno da Play Console e verificar o
  relatório de pré-lançamento.
- [ ] Corrigir qualquer erro de estabilidade, acessibilidade ou compatibilidade
  apontado pelo relatório de pré-lançamento.

## Privacidade, saúde e IA

- [x] Política pública disponível em
  `https://julianocarvalho1.github.io/pulse-app/politica-de-privacidade/`.
- [x] Política acessível dentro do app em Configurações > Privacidade e
  assistência.
- [x] Explicação destacada aparece antes da permissão do Android para câmera.
- [x] App não contém anúncios, analytics ou SDKs de rastreamento.
- [x] Aviso de que o Assistente não diagnostica nem substitui profissionais.
- [x] Atualizar no GitHub Pages a revisão local da política de privacidade.
- [ ] Preencher a declaração de Apps de saúde como **Atividade e fitness**.
- [ ] Preencher Segurança dos dados somente depois de confirmar os registros do
  Worker. O contexto de treino enviado à IA é informação de fitness coletada de
  forma opcional para funcionalidade do app.
- [ ] Preencher classificação de conteúdo e declarar o recurso de IA generativa.
- [x] Disponibilizar relato de problema em resposta de IA dentro do app sem
  depender de abrir outro aplicativo.

## Ficha da loja

- [x] Título, descrição curta e descrição completa preparados em `LOJA_PT_BR.md`.
- [x] Arte original do ícone do aplicativo incorporada aos launchers Android e
  iOS, incluindo ícone adaptativo no Android.
- [ ] Exportar a arte original em PNG de 512 x 512, sem transparência e com até
  1 MB, para a ficha da Google Play.
- [ ] Imagem de destaque de 1024 x 500.
- [ ] Pelo menos duas capturas de tela de telefone válidas; quatro são
  recomendadas.
- [ ] Revisar todos os textos e imagens para não prometer diagnóstico, tratamento
  ou resultado físico garantido.
- [ ] Informar e-mail de suporte: `pulse.appp@gmail.com`.
- [ ] Definir público-alvo. Recomendação inicial: somente 18 anos ou mais, para
  reduzir obrigações adicionais envolvendo menores e saúde.
- [ ] Confirmar categoria **Saúde e fitness**.

## Teste e publicação

- [ ] Executar toda a `MATRIZ_TESTES_MANUAIS.md` na versão assinada.
- [x] Fazer backup, apagar os dados, restaurar e comparar fichas/histórico.
- [x] Testar atualização sobre uma versão anterior sem perder dados.
- [ ] Verificar o tamanho de download exibido pela Play Console.
- [ ] Usar publicação gerenciada no primeiro lançamento.
- [ ] Iniciar com distribuição pequena/fechada, acompanhar travamentos e somente
  então liberar produção.

## Tipo da conta — aguardando orientação da Google Play

O PULSE se enquadra na declaração de saúde como **Atividade e fitness**, pois
registra exercícios, rotinas e treinos. As páginas oficiais sobre tipos de conta
e apps de saúde não eliminam toda a ambiguidade para um desenvolvedor individual
sem empresa, especialmente diante das mudanças anunciadas para 2026.

O chamado `9-5259000041100` foi aberto em 8 de agosto de 2026. Até 9 de agosto,
o suporte havia enviado somente a confirmação de recebimento. Aguardar a
resposta escrita antes de converter a conta, abrir empresa ou assumir qualquer
custo recorrente.

Referências oficiais:

- [Requisitos de API alvo](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Declaração de apps de saúde](https://support.google.com/googleplay/android-developer/answer/14738291)
- [Política de conteúdo gerado por IA](https://support.google.com/googleplay/android-developer/answer/13985936)
- [Teste fechado para novas contas pessoais](https://support.google.com/googleplay/android-developer/answer/14151465)
- [Requisitos dos recursos gráficos](https://support.google.com/googleplay/android-developer/answer/9866151)
- [Requisitos da Play Console e tipos de conta](https://support.google.com/googleplay/android-developer/answer/10788890)
- [Conversão de conta pessoal em organização](https://support.google.com/googleplay/android-developer/answer/16260648)
