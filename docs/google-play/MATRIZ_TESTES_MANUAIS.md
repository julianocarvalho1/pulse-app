# Matriz de testes manuais

Marque cada item em pelo menos um aparelho físico e repita os críticos no AAB
distribuído pelo teste interno da Google Play.

| Área | Cenário | Resultado esperado | Estado |
| --- | --- | --- | --- |
| Instalação | Estado local limpo | Abre onboarding sem erro ou tela vazia persistente | [x] 09/08/2026 — exclusão integral no Xiaomi M2012K11AG, Android 13 |
| Onboarding | Avançar com nome vazio | Mostra validação clara e preserva os demais campos | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Onboarding | Concluir com valores válidos | Abre início e mantém preferências após reiniciar | [x] 09/08/2026 — preferências confirmadas no gerador após reinícios |
| Início | Fonte padrão e 130% | Sem texto cortado ou faixa de overflow | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Início | Tela pequena | Conteúdo rola e navegação inferior permanece utilizável | [x] 09/08/2026 — 900x2000 a 440 dpi (~327 dp), sem overflow e com navegação utilizável |
| Programas | Importar programa | Fichas corretas aparecem em Meus treinos e o programa pode ser removido com confirmação | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Fichas | Criar, editar e excluir | Mudanças persistem e a exclusão exige confirmação | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Fichas | Duplicar ficha | Cria uma cópia editável sem alterar a original | [ ] melhoria pós-lançamento |
| Exercícios | Buscar por nome ou apelido | Encontra o exercício canônico em português e inglês | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Exercícios | Filtrar e pesquisar sem resultado | Filtro e estado vazio são coerentes | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Exercícios | Abrir demonstrações | Mídia correta do RepDB carrega sem travar | [x] amostra física + cobertura automatizada do catálogo |
| Gerador | Valores válidos | Usa preferências e gera rotina revisável antes de salvar | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Gerador | Restrições/sinais de risco | Exibe orientação e bloqueia a geração de forma apropriada | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Treino | Iniciar, registrar séries e descanso | Valores persistem e o descanso permite ajustar, pausar, continuar e pular | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Treino | Minimizar e voltar | Sessão e tempo não são perdidos ou duplicados | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Treino | Descartar sessão | Exige confirmação e não cria item no histórico | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Treino | Finalizar sessão com atividade | Exige confirmação e cria o histórico correto | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Histórico | Excluir item | Exige confirmação e recalcula as métricas sem inconsistência | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Histórico | Editar item | Permite corrigir dados registrados sem recriar o treino | [ ] melhoria pós-lançamento |
| Progresso | Períodos e gráficos | Valores batem com o histórico inserido | [ ] |
| Progresso | Analisar com histórico | Gera a leitura no aparelho e informa que as métricas não são enviadas | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Medidas | Criar e excluir avaliação | Dados persistem, unidades são claras e a exclusão exige confirmação | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Medidas | Editar avaliação existente | Permite corrigir uma avaliação sem recriá-la | [ ] melhoria pós-lançamento |
| QR Code | Negar câmera | App continua utilizável e explica como tentar novamente | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| QR Code | Conceder e ler código válido | Abre revisão antes de importar | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| QR Code | Ler ficha que já existe | Identifica a duplicidade e não sobrescreve os dados | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| QR Code | Código inválido | Mostra erro seguro, sem travar ou importar parcialmente | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Arquivo | Salvar ficha como arquivo .pulse | Arquivo é criado no destino escolhido | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Arquivo | Compartilhar ficha com outro aplicativo | Seletor do Android abre e o destino recebe o arquivo | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Arquivo | Importar arquivo válido que já existe | Abre revisão e evita duplicação ou sobrescrita silenciosa | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Arquivo | Importar arquivo inválido | Mostra erro seguro e mantém os dados atuais | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Backup | Exportar backup | Arquivo JSON válido é salvo e pode ser copiado para outro local | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Backup | Restaurar backup | Mostra revisão, exige confirmação e recupera os dados esperados | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Backup | Arquivo corrompido | Falha com mensagem e mantém dados atuais | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Biometria | Ativar, bloquear e autenticar | Android faz a autenticação e app desbloqueia uma vez | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Biometria | Cancelar/falhar | Dados permanecem protegidos e há saída compreensível | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Assistente | Sem internet | Usa contingência local e explica a limitação | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Assistente | Resposta online | Avisos aparecem e conteúdo não inventa dados ausentes | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Assistente | Relatar problema | Relato é gravado no servidor e o app confirma o recebimento | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Links | Política e apps de música | Abrem o destino correto ou mostram falha amigável | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Privacidade | Apagar todos os dados | Retorna ao estado inicial sem resíduos visíveis | [x] 09/08/2026 — backup restaurado após a validação |
| Atualização | Instalar build novo sobre anterior | Banco migra e dados existentes permanecem | [x] múltiplas atualizações em 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Acessibilidade | TalkBack | Ordem, nomes dos controles e ações principais são claros | [ ] |
| Acessibilidade | Contraste/tema escuro | Conteúdo essencial permanece legível | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Interrupções | Rotação, chamada, pouca memória | Operação crítica é preservada ou recuperada com segurança | [ ] |
| Desempenho | Primeira abertura e listas longas | Sem congelamento persistente ou consumo anormal | [x] 09/08/2026 — abertura fria debug em 2,72 s e catálogo com 200 exercícios sem congelamento no Xiaomi M2012K11AG |

## Aparelhos mínimos sugeridos

- Android 7 ou 8, se houver acesso a aparelho/emulador antigo;
- Android 12 a 14 em celular físico intermediário;
- Android 16, incluindo imagem de sistema com páginas de memória de 16 KB;
- uma tela pequena e uma tela grande;
- aparelho sem biometria cadastrada e aparelho com biometria.

Não é necessário comprar aparelhos. Use celulares emprestados de participantes,
emuladores oficiais e o relatório de pré-lançamento gratuito da Play Console.
