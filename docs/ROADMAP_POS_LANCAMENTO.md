# Roadmap pós-lançamento do PULSE

Atualizado em 1º de setembro de 2026.

Este documento é a referência única para as próximas versões do PULSE. Uma
funcionalidade só muda de fase quando os critérios de conclusão da fase atual
forem atendidos.

## Princípios do produto

- Continuar gratuito, sem anúncios e útil sem assinatura.
- Priorizar simplicidade, funcionamento offline e preservação dos dados.
- Respeitar a ficha criada pelo usuário ou pelo profissional responsável.
- Manter cálculos importantes locais, determinísticos e explicáveis.
- Não enviar anotações livres, histórico ou métricas de progressão à IA.
- Não adicionar mídia sem origem e licença documentadas.
- Fazer mudanças visuais incrementais, sem redesenhar o aplicativo inteiro.

## Situação atual

- [x] Versão `1.0.0` publicada no Google Play em 21 de agosto de 2026.
- [x] Biblioteca offline com mídia do RepDB Free Tier e atribuição visível.
- [x] Backup, importação, compartilhamento e retomada de sessão disponíveis.
- [x] Assistente local e online com proteção da cota gratuita.
- [ ] Primeira atualização pós-lançamento preparada e validada.

## Versão 1.1.0 — Controle e progressão

Objetivo: corrigir as sugestões atuais e permitir registrar o contexto de cada
exercício sem alterar a ficha original.

### Progressão explicável

- [x] Corrigir o caso que sugere 13 repetições em uma faixa `8–12` quando a
  carga está vazia ou igual a zero.
- [x] Interpretar a faixa da ficha e eventuais alvos individuais por série como
  limites obrigatórios.
- [x] Avaliar todas as séries comparáveis do último treino, não somente a
  série de maior carga ou maior repetição.
- [x] Nunca sugerir repetições acima do máximo prescrito.
- [x] Remover o aumento fixo e arbitrário de `2,5 kg`.
- [ ] Oferecer os modos **Seguir a ficha**, **Dentro da faixa** e
  **Repetições e depois carga**.
- [ ] Usar esforço informado/RIR somente como dado auxiliar e opcional.
- [x] Permitir marcar uma execução como **carga não comparável**, por exemplo
  quando outra máquina foi usada.
- [ ] Exibir a origem da sugestão: faixa prescrita, desempenho anterior e
  motivo da recomendação.
- [ ] Cobrir faixas, alvos fixos, exercícios sem carga, isometrias e
  prescrições descendentes com testes automatizados.

Referências de produto:

- [ACSM 2026 — prescrição individualizada de treinamento resistido](https://pubmed.ncbi.nlm.nih.gov/41843416/)
- [ACSM 2009 — modelos de progressão](https://pubmed.ncbi.nlm.nih.gov/19204579/)
- [Progressão por carga ou repetições, Plotkin et al. 2022](https://pubmed.ncbi.nlm.nih.gov/36199287/)
- [Limitações da estimativa de repetições em reserva](https://pubmed.ncbi.nlm.nih.gov/33337690/)

### Anotações do exercício

- [x] Usar somente o rótulo **Anotações**.
- [x] Adicionar uma anotação por exercício em cada sessão, aplicável ao
  conjunto de séries daquele exercício.
- [x] Diferenciar a anotação realizada durante o treino da orientação já
  cadastrada na ficha.
- [x] Salvar automaticamente durante a sessão.
- [x] Restaurar a anotação após fechar e reabrir o aplicativo.
- [x] Exibir a anotação nos detalhes do histórico.
- [x] Incluir a anotação em backup, importação e exportação.
- [x] Não copiar automaticamente a anotação para o treino seguinte.
- [ ] Oferecer atalhos estruturados como **Máquina diferente** e
  **Carga não comparável**, mantendo o texto livre opcional.

### Critérios para concluir a versão 1.1.0

- [x] Migração do banco preserva todo o histórico da versão `1.0.0`.
- [x] Sessão em andamento volta com cargas, repetições, descanso e anotações.
- [x] Backup antigo importa normalmente; backup novo preserva os novos campos.
- [x] `flutter analyze` e todos os testes automatizados passam.
- [x] APK instalado por atualização no celular físico sem limpar os dados.
- [ ] Progressão e anotações aprovadas em teste manual durante um treino real.

## Versão 1.2.0 — Core e séries por tempo

Objetivo: permitir sessões extras de core sem alterar a sequência ABCDE e dar
suporte real a pranchas, isometrias e circuitos.

### Atualização controlada do RepDB

- [ ] Baixar um novo snapshot oficial do RepDB Free Tier em diretório
  temporário.
- [ ] Comparar a licença atual com a licença arquivada no PULSE.
- [ ] Confirmar novamente uso comercial, armazenamento offline e atribuição.
- [ ] Importar somente os exercícios selecionados, sem substituir IDs de
  fichas já existentes.
- [ ] Priorizar **Dead Bug**, **Bird-Dog**, **Cable Pallof Press** e variações
  úteis de core disponíveis no catálogo gratuito atual.
- [ ] Criar nomes e aliases em português brasileiro.
- [ ] Atualizar manifesto SHA-256, inventário de licenças e testes do catálogo.
- [ ] Manter a atribuição visível em **Sobre o PULSE**.

### Sessões extras

- [ ] Criar uma área **Sessões extras** separada da sequência do programa.
- [ ] Adicionar **Core expresso**, **Core completo** e **Core em circuito**.
- [ ] Permitir iniciar uma sessão extra sem avançar, concluir ou substituir a
  próxima ficha ABCDE.
- [ ] Registrar a sessão extra normalmente no histórico e no progresso.
- [ ] Permitir copiar uma sessão pronta para personalização.

### Séries por tempo

- [ ] Permitir escolher repetição ou duração como alvo da série.
- [ ] Adicionar cronômetro por série com iniciar, pausar, retomar e concluir.
- [ ] Iniciar o descanso correto após uma série cronometrada.
- [ ] Preservar cronômetro e estado ao sair temporariamente do aplicativo.
- [ ] Registrar duração planejada e realizada no histórico.
- [ ] Tratar **Core em circuito** como circuito cronometrado; usar o nome
  **Tabata** somente quando o protocolo realmente corresponder a ele.

### Critérios para concluir a versão 1.2.0

- [ ] Toda mídia nova possui origem, licença e hash documentados.
- [ ] Nenhum material do RepDB foi enviado a uma ferramenta generativa.
- [ ] Sessões extras não alteram a próxima ficha do programa ativo.
- [ ] Cronômetros continuam corretos com tela apagada e troca de aplicativo.
- [ ] Exercícios de core e séries por tempo aprovados em celular físico.

## Versão 1.3.0 — Cardio 2.0

Objetivo: substituir a orientação genérica de cardio por planejamento
estruturado e editável.

- [ ] Consolidar os formulários duplicados de cardio em um único componente.
- [ ] Adicionar finalidade: aquecimento, pós-treino ou sessão separada.
- [ ] Adicionar formato contínuo ou intervalado.
- [ ] Adicionar intensidade, esforço percebido e teste da fala em linguagem
  simples.
- [ ] Permitir velocidade, inclinação, resistência e distância quando
  aplicáveis à modalidade.
- [ ] Para intervalados, permitir aquecimento, esforço, recuperação, ciclos e
  desaceleração.
- [ ] Criar modelos editáveis: livre, contínuo leve, contínuo moderado e
  intervalado.
- [ ] Manter compatibilidade com fichas, backups e QR Codes anteriores.
- [ ] Testar execução offline, retomada e histórico de cada modalidade.

## Versão 1.4.0 — Refinamentos de treino e feedback

- [ ] Diferenciar séries de aquecimento e séries de trabalho.
- [ ] Permitir descanso próprio para aquecimento.
- [ ] Avaliar registro separado de lado direito e esquerdo em exercícios
  unilaterais.
- [ ] Implementar avaliação nativa do Google Play após uso suficiente, sem
  pedir nota específica ou oferecer recompensa.
- [ ] Criar uma tela curta de **Novidades da versão**.
- [ ] Revisar aquecimento, mobilidade e alongamento para uma fase posterior.

## Experimento separado — animações próprias com IA

Este experimento não bloqueia as versões 1.1.0 a 1.3.0.

- [ ] Selecionar somente um exercício que não possua mídia adequada no RepDB.
- [ ] Definir personagem e direção visual originais, sem copiar o estilo nem
  usar imagens do RepDB como referência.
- [ ] Gerar um clipe curto e silencioso a partir de texto ou material próprio.
- [ ] Verificar termos comerciais, marca-d'água, custo e possibilidade de uso
  no aplicativo na data da geração.
- [ ] Fazer revisão quadro a quadro da postura, amplitude, equipamento e
  continuidade do movimento.
- [ ] Obter validação de um profissional de educação física antes do uso.
- [ ] Registrar ferramenta, plano, data, prompt, arquivo original, termos e
  decisão no inventário de mídia.
- [ ] Testar tamanho, qualidade, loop, consumo de memória e acessibilidade.
- [ ] Publicar somente se o resultado for correto, consistente, documentado e
  sustentável sem custo recorrente.

### Restrições importantes

- A licença do RepDB proíbe usar suas imagens como entrada, referência ou
  condicionamento de modelos generativos.
- O Google Flow gratuito pode ser útil para protótipos, mas seus vídeos incluem
  SynthID e, nos planos Free, Plus e Pro, marca-d'água visível. Ela não deve ser
  removida ou escondida.
- Vídeo gerado por IA pode apresentar postura ou movimento incorretos. Nenhum
  clipe entra no PULSE apenas porque parece visualmente bom.

Referências:

- [Catálogo gratuito atual do RepDB](https://github.com/RepDB/exercise-dataset)
- [Lista atual de exercícios do RepDB](https://repdb.co/exercises/)
- [Créditos e custos do Google Flow](https://support.google.com/flow/answer/16526234?hl=pt-BR)
- [Uso, propriedade do conteúdo e marca-d'água no Google Flow](https://support.google.com/flow/answer/16353333?hl=pt-BR)

## Itens fora do foco por enquanto

- Rede social e feed público.
- Integração com vários smartwatches.
- Estimativa genérica de calorias.
- Alimentação e dieta.
- Assinaturas, anúncios e paywall.
- Reformulação visual completa.

Esses itens só serão reconsiderados após feedback real dos usuários e depois de
as funções principais estarem estáveis.

## Portão obrigatório de cada publicação

- [ ] Atualizar este roadmap e o `CHANGELOG.md`.
- [ ] Revisar mudanças de banco e compatibilidade com backups antigos.
- [ ] Executar formatação, análise estática e testes automatizados.
- [ ] Instalar por cima da versão pública em celular físico.
- [ ] Confirmar que ficha, histórico, sessão ativa e configurações permanecem.
- [ ] Executar os testes manuais da funcionalidade alterada.
- [ ] Revisar privacidade, declarações da Play e licenças de novas mídias.
- [ ] Gerar AAB assinado com novo `versionCode`.
- [ ] Verificar relatório de pré-lançamento antes de liberar gradualmente.
- [ ] Acompanhar travamentos, relatos e avaliações depois da publicação.
