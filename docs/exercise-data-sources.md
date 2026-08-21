# Fontes de dados e mídia de exercícios

Atualizado em 9 de agosto de 2026.

## Fonte utilizada: RepDB Free Tier

O PULSE usa um snapshot obtido em 8 de agosto de 2026 do RepDB Free Tier:

- 200 imagens WebP armazenadas no aplicativo para funcionamento offline;
- IDs próprios do PULSE preservados para não quebrar fichas existentes;
- IDs do RepDB usados apenas na camada de correspondência e mídia;
- nomes em português e sinônimos de busca mantidos pelo PULSE;
- atribuição visível em **Sobre o PULSE > Créditos e licenças**.

O arquivo `third_party/repdb/LICENSE-DATA.md` v1.0 permite uso pessoal e
comercial dentro de aplicativos, inclusive das imagens, com atribuição. Ele
proíbe redistribuir o material como dataset, repositório de dataset ou API.

Em resposta enviada por e-mail em 9 de agosto de 2026, o responsável pelo
RepDB confirmou que essa licença rege os dados e imagens do free tier e que a
inclusão offline no APK/AAB é permitida, desde que o link de atribuição permaneça
visível. O e-mail original deve ser preservado na conta de suporte do PULSE como
evidência complementar.

Integridade dos arquivos incorporados:

- `third_party/repdb/ASSET-MANIFEST.sha256`.

Texto exibido no aplicativo:

> Exercise data by RepDB (repdb.co)

## Fonte avaliada e não utilizada: ExerciseDB V1 gratuito

O ExerciseDB/AscendAPI informou por e-mail em 9 de agosto de 2026 que os dados e
mídias gratuitos servidos por `oss.exercisedb.dev` são destinados somente a
uso educacional e não comercial. A resposta também proibiu armazenamento local,
uso offline, redistribuição dentro de APK/AAB e inclusão de versões modificadas
ou otimizadas das mídias.

Por esse motivo, nenhum dado ou arquivo de mídia do ExerciseDB gratuito pode
ser incorporado ao PULSE. A alternativa comercial não foi adotada por envolver
custo e não ser necessária para o lançamento.

## Regras de manutenção

- Não adicionar GIFs ou imagens obtidos por busca na internet.
- Não importar novas versões do RepDB sem revisar a licença vigente.
- Não publicar os arquivos do RepDB como dataset separado do aplicativo.
- Manter a atribuição visível enquanto qualquer dado ou mídia do RepDB for usado.
- Atualizar o inventário em `docs/google-play/inventario-licencas-midias.csv`
  sempre que um ativo for adicionado ou substituído.
