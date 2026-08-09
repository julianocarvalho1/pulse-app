# Guia de preenchimento da Play Console

Use este arquivo como rascunho. Os nomes das perguntas podem mudar na Play
Console. Nunca marque uma resposta apenas para passar na revisão: ela precisa
descrever o binário enviado e o comportamento real do backend.

## Identidade do app

- Nome: **PULSE: Treinos e Progresso**
- Pacote: `com.julianocarvalho.pulse`
- Categoria: **Saúde e fitness**
- E-mail de suporte: `pulse.appp@gmail.com`
- Política de privacidade:
  `https://julianocarvalho1.github.io/pulse-app/politica-de-privacidade/`
- Anúncios: **não contém anúncios**
- Acesso ao app: **todas as funções básicas estão disponíveis sem conta**. O
  bloqueio biométrico é opcional e vem desativado em uma instalação nova.

O nome do pacote é permanente depois do primeiro envio. Confirme-o antes de
criar a ficha.

## Público-alvo e conteúdo

Recomendação para a versão 1.0: selecionar apenas faixas de **18 anos ou mais**.
O app não foi criado para crianças e envolve treino, medidas corporais e
orientações informativas de saúde/fitness. Se for decidido atender menores,
será necessária uma nova revisão de UX, política e obrigações para famílias.

Na classificação de conteúdo:

- responder que há interação com IA se a versão online continuar ativa;
- não há violência, apostas, sexualidade, drogas ou compras no app conhecidas;
- revisar cada pergunta na própria Play Console, pois a classificação final é
  calculada pelo questionário.

## Declaração de apps de saúde

- O app possui recursos de saúde: **sim**.
- Categoria: **Atividade e fitness**.
- Não declarar dispositivo médico, diagnóstico, tratamento ou pesquisa clínica.
- Descrever que registra treinos, cargas, histórico e medidas inseridas pelo
  usuário, com orientações apenas informativas.
- A política de privacidade está no app e na ficha pública.

## Tipo da conta de desenvolvedor

A declaração acima não pede MEI diretamente, mas o requisito de conta é
separado. O chamado `9-5259000041100` foi aberto para confirmar como a regra se
aplica a um app de Atividade e fitness publicado por desenvolvedor individual.
Aguardar e arquivar a resposta escrita antes de converter a conta ou abrir uma
entidade. Não alterar a categoria real do aplicativo para contornar a regra.

## Permissões

- Câmera: leitura de QR Code de treino iniciada pelo usuário. As imagens são
  processadas no dispositivo, não são salvas e não são enviadas.
- Biometria: o Android autentica o usuário; o PULSE recebe somente sucesso ou
  falha e não acessa o dado biométrico.
- Internet: abrir páginas/serviços externos e usar o Assistente online.

Não há permissão de localização, contatos, microfone, telefone, SMS ou acesso
amplo ao armazenamento.

## Segurança dos dados — base para conferência no formulário

### Dados no aparelho

Fichas, histórico, cargas, medidas, preferências, observações e foto ficam
localmente. Pela regra da Play, dados processados somente no dispositivo não são
declarados como coletados. Exportação/compartilhamento iniciado pelo usuário é
tratado separadamente conforme as instruções do formulário.

### Assistente online

Na versão atualmente testada, quando o usuário aciona o Assistente online, o app
transmite por HTTPS somente um contexto técnico estruturado do treino. Nome da
ficha, observações livres e métricas detalhadas de progresso permanecem no
aparelho. O serviço usa uma identificação aleatória da instalação, sem conta,
para aplicar limites de cota. Para preencher a ficha do binário atual, revisar
de forma conservadora:

- tipo: **Informações de saúde e fitness > Informações de fitness**;
- coleta: **sim, opcional**;
- finalidade: **Funcionalidade do app**;
- **Identificadores do dispositivo ou outros IDs**: revisar a identificação
  aleatória da instalação usada para limitar a cota;
- **Atividade no app > Outro conteúdo gerado pelo usuário**: revisar o comentário
  opcional enviado em um relato de problema;
- processamento temporário: **não** para as informações mantidas conforme os
  períodos de retenção abaixo;
- compartilhamento: Cloudflare e Google processam os dados para fornecer a
  funcionalidade. Conferir a definição de prestador de serviço exibida no
  formulário antes de marcar se isso conta como compartilhamento;
- criptografado em trânsito: **sim, HTTPS**;
- exclusão: dados locais podem ser apagados no app; solicitações sobre dados do
  backend usam o e-mail de suporte.

Retenção documentada no Worker:

- contadores ligados ao hash da instalação: até 14 dias;
- respostas online: até 45 dias;
- relatos, resposta relacionada, motivo e comentário: até 180 dias;
- amostragem de observabilidade do Worker: 5%, sem registrar o conteúdo de
  solicitações ou respostas por `console`.

## IA generativa

A chamada online permanecerá na versão 1.0:

- declarar o recurso de IA generativa;
- manter avisos contra diagnóstico e prescrição;
- o relato de problema já está disponível dentro do app e vinculado à resposta;
- os relatos são armazenados no D1 para revisão e prevenção de abuso.

## Exclusão de conta

O PULSE não cria contas. Se o formulário perguntar por exclusão de conta,
responder que o app não oferece criação de conta. O usuário pode apagar dados em
Configurações > Dados e backup, limpar os dados do Android ou desinstalar.
