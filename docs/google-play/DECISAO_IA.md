# Assistente PULSE online — implementação aprovada

O PULSE será lançado com assistência online para explicações e revisões técnicas
de fichas e exercícios. A análise de métricas de progresso permanece local no
aparelho para reduzir o tratamento de dados de atividade física.

## Estado implantado em 9 de agosto de 2026

- `POST /assist` aceita apenas protocolo estruturado versão 2;
- prompts livres e versões antigas são bloqueados antes do Gemini;
- identificador aleatório por instalação, armazenado no D1 somente como hash;
- limite de 3 solicitações por minuto por instalação;
- limite exato de 10 análises online por instalação/dia;
- teto global exato de 150 análises online/dia;
- fallback local quando há falha, ausência de internet ou cota esgotada;
- `POST /report` implantado e vinculado à resposta/instalação original;
- formulário de relato de problema dentro do app com motivo e comentário opcional;
- registros em D1 com retenção de 14 dias para contadores, 45 dias para
  respostas e 180 dias para relatos;
- amostragem de logs do Worker reduzida de 100% para 5%, sem registrar o
  conteúdo de solicitações ou respostas em `console`;
- modelo online: `gemini-3.5-flash-lite`;
- Worker publicado: `https://pulse-ai-api.pulse-appp.workers.dev`.

## Operação sem custo obrigatório

O Worker, o D1, o Rate Limiting binding e o Gemini estão configurados nos planos
gratuitos atuais, sem ativação de cobrança. Os tetos do próprio PULSE são
intencionalmente menores que os limites de infraestrutura e podem ser ajustados
em `C:\Users\User\pulse-ai-api\wrangler.jsonc`.

Para consultar relatos pendentes:

```powershell
cd C:\Users\User\pulse-ai-api
npx wrangler d1 execute pulse-ai-guard --remote --command "SELECT id, mode, category, comment, response_text, created_at FROM content_reports WHERE status = 'pending' ORDER BY created_at"
```

Depois da revisão, o status pode ser atualizado para `reviewed`. Não copie
respostas ou comentários para serviços públicos.

## Antes de enviar à produção da Google Play

1. executar os testes e a validação de release do aplicativo;
2. confirmar no APK final uma resposta online e o formulário de relato;
3. publicar a política de privacidade atualizada;
4. preencher Segurança dos dados de acordo com o comportamento documentado;
5. revisar periodicamente relatos pendentes e o consumo diário do D1.

Referências:

- [Política da Google Play para conteúdo gerado por IA](https://support.google.com/googleplay/android-developer/answer/13985936)
- [Termos da API Gemini](https://ai.google.dev/gemini-api/terms)
- [Limites do Gemini](https://ai.google.dev/gemini-api/docs/rate-limits)
- [Rate Limiting binding do Cloudflare](https://developers.cloudflare.com/workers/runtime-apis/bindings/rate-limit/)
