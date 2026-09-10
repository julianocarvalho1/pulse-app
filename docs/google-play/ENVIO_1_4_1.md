# Atualização 1.4.1 — código 7

Preparação: 9 de setembro de 2026.
Pacote: `com.julianocarvalho.pulse`.

## Escopo

- Cardio guiado, animação de etapas e voz opcional.
- Editor de intervalos com aquecimento/desaceleração únicos e ciclos explícitos.
- Escolha da próxima ficha ao salvar sessão incompleta do programa ativo.
- Banco v13 com migração aditiva e preservação do histórico.
- Notas da versão atualizadas no app e na Play.

Novas sugestões de funcionalidades ficam para outra atualização.

## Estado conferido antes do envio

A Play Console mostrou a 1.4.0 (código 6) em produção, lançamento 100%,
um país/região e nenhuma alteração pendente de publicação.
Publicação gerenciada ativada. Rascunho novo: produção, release 3.

## Recomendações da Play para revisão futura

- Exibição de ponta a ponta e APIs descontinuadas relacionadas.
- Redimensionamento/orientação em telas grandes.
- Redução de resolução de bitmaps para melhorar uso de memória.

## Validação e envio

- Formatação: 201 arquivos verificados, nenhuma alteração pendente de formato.
- `flutter analyze --no-pub`: nenhum problema encontrado.
- `flutter test --no-pub --reporter expanded`: 264 testes aprovados.
- `flutter build appbundle --release`: compilação concluída.
- Manifesto: pacote oficial, versão 1.4.1, código 7, minSdk 24, targetSdk 36.
- `jarsigner -verify`: `jar verified` (certificado de upload autoassinado;
  avisos de timestamp e leitura por JarInputStream emitidos pela ferramenta).
- AAB: `build/app/outputs/bundle/release/app-release.aab`.
- SHA-256: `B7C055196AD8C4B52A3C73A7D73F19D481E750C957C5800D81D97A79A0B8C014`.
- Play aceitou o AAB 7 (1.4.1); nenhum dispositivo perdeu compatibilidade.
- Estimativas da Play: instalação nova 25,3 MB, atualização 1,6 MB.
- Percentual 100% e países de destino existentes preservados.
- Envio confirmado na Play: **Alterações em análise**, versão
  `1.4.1 - Cardio guiado e sequência de treinos`; verificações rápidas em andamento.
- Publicação gerenciada mantida: após aprovação, ainda requer liberação manual.
- Ainda não publicado; a versão pública continua 1.4.0 (código 6).
- Código preparado no commit `71694a5`.

Próximo passo: conferir resultado da revisão e liberar a publicação quando
aprovada. Nenhum monitoramento automático foi criado.
