# Changelog

Todas as mudanças relevantes do PULSE serão registradas neste arquivo.

## [1.2.0] - em desenvolvimento

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

## [1.1.0] - em desenvolvimento

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
