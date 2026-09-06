# Changelog

Todas as mudanças relevantes do PULSE serão registradas neste arquivo.

## [1.4.0] - em desenvolvimento

### Corrigido

- botão **Salvar cardio** agora reserva a área da barra de navegação do Android
  e permanece totalmente visível na parte inferior da tela;
- adicionar cardio na edição da ficha preserva os exercícios de musculação e
  transforma a ficha em mista; a ação está disponível sem trocar o tipo antes;
- seleção de alternativas limitada ao mesmo grupo muscular, com verificação
  também ao substituir durante a sessão;
- fechamento da busca de alternativas com campo ativo não descarta o controle
  antes de concluir a animação, e a seleção permanece durante reconstruções.
- tela vermelha ao salvar ou cancelar a edição de uma série com um campo
  ativo, incluindo RIR; os controles agora permanecem válidos até o diálogo
  terminar de fechar.

### Incluído

- séries de aquecimento separadas das séries de trabalho, com identificação
  visual e descanso próprio;
- tela curta de novidades exibida uma vez por versão;
- solicitação nativa e discreta de avaliação pelo Google Play somente após uso
  suficiente do aplicativo.

### Alterado

- aquecimentos continuam salvos no histórico, mas não inflam volume, recordes
  pessoais nem sugestões de progressão;
- banco local atualizado para a versão 12 por migração aditiva;
- versão Android atualizada para `1.4.0` (`versionCode 6`).

### Decisão de produto

- o registro separado dos lados direito e esquerdo foi adiado: por enquanto,
  quando a ficha informa **por lado**, carga e repetições representam o valor
  realizado em cada lado. A separação só será adicionada se o uso real mostrar
  benefício suficiente para compensar o dobro de campos durante a sessão.

## [1.3.0] - não publicada separadamente

### Incluído

- planejamento de cardio com finalidade, formato e intensidade relativa;
- orientação simples pelo teste da fala e registro de esforço percebido;
- campos opcionais para distância, velocidade, inclinação e resistência;
- blocos editáveis de aquecimento, esforço, recuperação, ciclos e
  desaceleração para sessões intervaladas;
- modelos editáveis de cardio livre, contínuo leve, contínuo moderado e
  intervalado.

### Alterado

- os editores duplicados de cardio foram reunidos em um único componente;
- gerador, programas prontos e importador de fichas agora produzem planos de
  cardio estruturados sem modificar a orientação original do profissional;
- plano de cardio incluído em sessão ativa, histórico, backup, arquivo PULSE e
  QR Code, com leitura compatível de dados anteriores;
- banco local atualizado para a versão 11 por migração aditiva.

## [1.2.0] - não publicada separadamente

### Incluído

- área **Extras** com as sessões Core expresso, Core completo e Core em
  circuito, sem alterar a próxima ficha do programa ativo;
- suporte a séries por tempo, com iniciar, pausar, retomar, concluir e descanso
  após a execução;
- duração planejada e realizada no histórico, na sessão em andamento e nos
  backups;
- Dead Bug, Bird-Dog e Pallof Press na Polia, com imagens oficiais do catálogo
  gratuito do RepDB e nomes alternativos em português.

### Alterado

- catálogo de exercícios atualizado para a versão 4, preservando os IDs e
  nomes reconhecidos pela versão anterior;
- editor de prescrições agora permite escolher entre repetições e tempo por
  série;
- banco local atualizado para a versão 10 por migração aditiva.

## [1.1.0] - não publicada separadamente

### Incluído

- anotações por exercício durante a sessão, com restauração e histórico;
- modos de progressão que respeitam a faixa prescrita e nunca sugerem uma
  repetição acima do limite;
- registro opcional de RIR e de carga não comparável.

## [1.0.0] - 2026-08-21

### Incluído

- onboarding e preferências de treino;
- biblioteca, fichas, programas e gerador de treinos;
- preferências iniciais reutilizadas para pré-configurar o gerador de programas;
- biblioteca offline com mídia licenciada do RepDB, nomes em português e
  sinônimos de busca;
- criação de exercícios personalizados quando um movimento não existe no
  catálogo;
- execução de sessões, histórico, calendário e progresso;
- importação, exportação, backup e compartilhamento por QR Code;
- bloqueio opcional pelo sistema Android;
- Assistente PULSE local e online com avisos de segurança, proteção de cota e
  relato de problemas dentro do app.

### Preparação para lançamento

- Android 16 (`targetSdk 36`) e suporte a Android 7+;
- automação de análise, testes e build no GitHub Actions;
- configuração segura e opcional da assinatura de release;
- backup automático do Android desativado;
- câmera declarada como recurso opcional e explicação antes da permissão;
- política de privacidade acessível no app;
- edição do nome/apelido diretamente no perfil;
- correção de estouro visual nos atalhos da tela inicial;
- cronômetro total compacto na barra superior durante o treino;
- arte original e ícone adaptativo do PULSE.
