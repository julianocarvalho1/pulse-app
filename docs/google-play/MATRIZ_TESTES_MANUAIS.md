# Matriz de testes manuais

Marque cada item em pelo menos um aparelho físico e repita os críticos no AAB
distribuído pelo teste interno da Google Play.

| Área | Cenário | Resultado esperado | Estado |
| --- | --- | --- | --- |
| Instalação | Instalação limpa | Abre onboarding sem erro ou tela vazia persistente | [ ] |
| Onboarding | Avançar com nome vazio | Mostra validação clara e preserva os demais campos | [ ] |
| Onboarding | Concluir com valores válidos | Abre início e mantém preferências após reiniciar | [ ] |
| Início | Fonte padrão e 130% | Sem texto cortado ou faixa de overflow | [ ] |
| Início | Tela pequena | Conteúdo rola e navegação inferior permanece utilizável | [ ] |
| Programas | Importar programa | Fichas corretas aparecem em Meus treinos | [ ] |
| Fichas | Criar, editar, duplicar e excluir | Mudanças persistem e confirmação evita exclusão acidental | [ ] |
| Exercícios | Buscar e filtrar | Resultados e estado vazio são coerentes | [ ] |
| Exercícios | Abrir cada demonstração | Mídia correta do RepDB carrega sem travar | [ ] |
| Gerador | Valores válidos | Gera rotina revisável antes de salvar | [ ] |
| Gerador | Restrições/sinais de risco | Exibe orientação de segurança apropriada | [ ] |
| Treino | Iniciar, registrar séries e descanso | Progresso e temporizador permanecem corretos | [ ] |
| Treino | Minimizar e voltar | Sessão e tempo não são perdidos ou duplicados | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Treino | Descartar sessão | Exige confirmação e não cria item no histórico | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Treino | Finalizar sessão com atividade | Exige confirmação e cria o histórico correto | [ ] |
| Histórico | Editar/excluir item | Métricas são recalculadas sem inconsistência | [ ] |
| Progresso | Períodos e gráficos | Valores batem com o histórico inserido | [ ] |
| Progresso | Analisar com histórico | Gera a leitura no aparelho e informa que as métricas não são enviadas | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Medidas | Criar, editar e excluir avaliação | Dados persistem e unidades são claras | [ ] |
| QR Code | Negar câmera | App continua utilizável e explica como tentar novamente | [ ] |
| QR Code | Conceder e ler código válido | Abre revisão antes de importar | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| QR Code | Ler ficha que já existe | Identifica a duplicidade e não sobrescreve os dados | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| QR Code | Código inválido | Mostra erro seguro, sem travar ou importar parcialmente | [ ] |
| Arquivo | Salvar ficha como arquivo .pulse | Arquivo é criado no destino escolhido | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Arquivo | Compartilhar ficha com outro aplicativo | Seletor do Android abre e o destino recebe o arquivo | [ ] |
| Arquivo | Importar arquivo válido que já existe | Abre revisão e evita duplicação ou sobrescrita silenciosa | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Arquivo | Importar arquivo inválido | Mostra erro seguro e mantém os dados atuais | [ ] |
| Backup | Exportar, apagar e restaurar | Fichas, histórico, medidas e configurações retornam | [ ] |
| Backup | Arquivo corrompido | Falha com mensagem e mantém dados atuais | [ ] |
| Biometria | Ativar, bloquear e autenticar | Android faz a autenticação e app desbloqueia uma vez | [ ] |
| Biometria | Cancelar/falhar | Dados permanecem protegidos e há saída compreensível | [ ] |
| Assistente | Sem internet | Usa contingência local e explica a limitação | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Assistente | Resposta online | Avisos aparecem e conteúdo não inventa dados ausentes | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Assistente | Relatar problema | Relato é gravado no servidor e o app confirma o recebimento | [x] 09/08/2026 — Xiaomi M2012K11AG, Android 13 |
| Links | Política e apps de música | Abrem o destino correto ou mostram falha amigável | [ ] |
| Privacidade | Apagar todos os dados | Retorna ao estado inicial sem resíduos visíveis | [ ] |
| Atualização | Instalar build novo sobre anterior | Banco migra e dados existentes permanecem | [ ] |
| Acessibilidade | TalkBack | Ordem, nomes dos controles e ações principais são claros | [ ] |
| Acessibilidade | Contraste/tema escuro | Conteúdo essencial permanece legível | [ ] |
| Interrupções | Rotação, chamada, pouca memória | Operação crítica é preservada ou recuperada com segurança | [ ] |
| Desempenho | Primeira abertura e listas longas | Sem congelamento persistente ou consumo anormal | [ ] |

## Aparelhos mínimos sugeridos

- Android 7 ou 8, se houver acesso a aparelho/emulador antigo;
- Android 12 a 14 em celular físico intermediário;
- Android 16, incluindo imagem de sistema com páginas de memória de 16 KB;
- uma tela pequena e uma tela grande;
- aparelho sem biometria cadastrada e aparelho com biometria.

Não é necessário comprar aparelhos. Use celulares emprestados de participantes,
emuladores oficiais e o relatório de pré-lançamento gratuito da Play Console.
