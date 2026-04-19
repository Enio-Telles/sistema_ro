---
name: stitchuso
description: Use esta skill quando a tarefa envolver criação, refinamento ou exploração de interfaces no Stitch do Google. Ela ajuda a transformar objetivos de produto, prompts, imagens, wireframes, referências visuais, URL de marca e regras de design em telas de alta fidelidade para web ou mobile, com iteração rápida, consistência visual e handoff para Figma ou código. Palavras-chave: Stitch, Google Stitch, UI, UX, tela, layout, app, web, mobile, wireframe, imagem, prompt, design system, DESIGN.md, Figma, HTML, CSS, protótipo.
---

# Stitch: geração e refinamento de UI com IA

Você é um especialista em usar o Stitch para transformar ideias em interfaces de alta fidelidade, com foco em clareza de prompt, consistência visual, exploração de alternativas e preparação para handoff.

## Quando usar esta skill

Use esta skill quando a solicitação envolver qualquer uma destas situações:

- Criar telas de app ou web a partir de uma descrição em linguagem natural.
- Transformar wireframes, screenshots, rabiscos ou imagens de referência em UI digital.
- Explorar variações visuais, layouts, fluxos, estados e temas.
- Refinar interfaces já geradas no Stitch com instruções curtas e objetivas.
- Definir ou reaproveitar um design system com `DESIGN.md`.
- Preparar material para handoff a design ou desenvolvimento.
- Organizar um fluxo de trabalho entre ideação, prototipagem e exportação.

## O que esta skill faz

Esta skill ajuda o agente a:

1. Traduzir um objetivo de produto em um prompt forte para o Stitch.
2. Escolher a melhor entrada para a tarefa: texto, imagem, wireframe, referência visual, código ou regras de design.
3. Estruturar pedidos de geração de tela com contexto suficiente para evitar resultados genéricos.
4. Pedir iterações específicas em vez de comentários vagos.
5. Criar consistência entre telas usando tokens, componentes e `DESIGN.md`.
6. Solicitar múltiplas alternativas antes de convergir para uma direção.
7. Verificar usabilidade, hierarquia, responsividade e estados da interface.
8. Preparar saída para Figma, HTML/CSS ou ferramentas de desenvolvimento.

## Princípios de trabalho

### 1) Comece pela intenção, não pela estética

Antes de pedir uma tela, defina:

- qual problema a interface resolve;
- quem é o usuário;
- qual ação principal a tela deve incentivar;
- qual é a plataforma: web, mobile ou ambas;
- qual tom a experiência deve transmitir.

Evite prompts como:

- “faz uma tela bonita”
- “crie um dashboard moderno”

Prefira prompts com intenção de negócio e UX:

- “Crie uma tela mobile para acompanhar entregas em tempo real. O usuário precisa localizar rapidamente o pedido atual, ver ETA e falar com o suporte.”

### 2) Estruture todo prompt em blocos

Sempre que possível, monte o prompt com estes blocos:

#### Objetivo
Explique a finalidade da tela ou fluxo.

#### Usuário e contexto
Diga quem usa a interface e em que situação.

#### Ação principal
Defina o que a pessoa precisa fazer sem esforço.

#### Conteúdo obrigatório
Liste elementos indispensáveis: formulário, tabela, gráfico, CTA, filtros, cards, navegação, empty state, erro, loading.

#### Direção visual
Descreva o estilo desejado: sóbrio, editorial, fintech, B2B, consumer, premium, playful, minimalista, denso, leve, etc.

#### Restrições
Inclua cor, grid, acessibilidade, idioma, branding, densidade, tamanho de tela, tipo de navegação, limitações técnicas.

### 3) Seja específico sobre a estrutura da interface

Ao pedir uma tela, detalhe a anatomia dela. Por exemplo:

- header com busca e ações rápidas;
- sidebar com navegação por módulos;
- área principal com cards de KPI;
- tabela com filtros, ordenação e paginação;
- painel lateral com detalhes do item selecionado.

Quanto mais concreta for a composição, melhor tende a ser o primeiro resultado.

### 4) Use referências como contexto, não como muleta

Quando houver imagem, screenshot, wireframe, rascunho ou app de referência:

- diga o que deve ser preservado: estrutura, fluxo, densidade, tom visual ou padrão de navegação;
- diga o que deve mudar: branding, paleta, tipografia, conteúdo, componentes ou complexidade;
- não peça apenas “copie isso”.

Prefira:

- “Use esta referência pela organização do conteúdo e pelo padrão de navegação. Não replique a estética literalmente. Adapte para um produto SaaS financeiro com visual mais limpo e profissional.”

### 5) Quando consistência importar, crie ou atualize o DESIGN.md

Use `DESIGN.md` quando o projeto exigir repetibilidade entre várias telas.

Inclua nele, em linguagem clara:

- princípios da marca;
- paleta principal e de apoio;
- tipografia;
- espaçamento;
- bordas e raios;
- elevação/sombras;
- estilos de botão;
- campos de formulário;
- tabelas, cards, modais e navegação;
- regras de uso de cor semântica;
- tom visual e sensação desejada.

Se existir um site de referência da marca, extraia as regras visuais dele e normalize em `DESIGN.md` antes de gerar muitas telas.

### 6) Itere com instruções pequenas e cirúrgicas

Depois da primeira geração, não reescreva tudo. Faça edições localizadas.

Boas instruções:

- “Reduza a altura do header e aumente o contraste dos KPIs.”
- “Troque a navegação inferior por sidebar compacta.”
- “Deixe o formulário em duas colunas no desktop e uma no mobile.”
- “Gere uma versão mais editorial e outra mais utilitária.”
- “Mostre estados de loading, vazio e erro para esta tela.”

Evite:

- “não gostei”
- “deixa melhor”
- “faz mais bonito”

### 7) Gere variantes antes de escolher uma direção

Quando a direção ainda não estiver clara, peça pelo menos 3 variações com diferenças reais:

- uma opção mais minimalista;
- uma mais orientada a dados;
- uma mais quente e amigável;
- uma premium;
- uma operacional/densa;
- uma mais voltada a conversão.

Depois compare:

- clareza da hierarquia;
- velocidade de leitura;
- adequação à marca;
- adequação ao usuário;
- facilidade de implementação.

### 8) Pense em fluxos, não só em telas isoladas

Quando fizer sentido, peça o conjunto mínimo de telas:

- onboarding;
- login;
- dashboard;
- detalhe;
- edição/criação;
- confirmação;
- erro;
- sucesso;
- empty state.

Sempre nomeie a jornada:

- entrada;
- decisão;
- ação;
- confirmação;
- retorno.

### 9) Verifique qualidade antes do handoff

Antes de considerar uma tela pronta, revise:

- hierarquia visual clara;
- CTA principal inequívoco;
- contraste suficiente;
- consistência entre componentes;
- estados vazios, erro e carregamento;
- responsividade;
- densidade adequada para o contexto;
- texto plausível e coerente;
- alinhamento com o design system.

### 10) Feche com saída acionável

Ao terminar, organize a resposta em uma destas formas:

- prompt final para colar no Stitch;
- plano de iteração em 3 a 5 passos;
- checklist de revisão visual;
- `DESIGN.md` inicial;
- lista de telas do fluxo;
- instruções de exportação e handoff.

## Fluxo recomendado

### Fluxo A: ideia -> prompt -> geração
Use quando o usuário ainda está no começo.

1. Entenda o objetivo do produto.
2. Defina plataforma, usuário e ação principal.
3. Escreva um prompt estruturado.
4. Gere 2 a 4 direções.
5. Escolha uma e refine.

### Fluxo B: wireframe/imagem -> UI de alta fidelidade
Use quando já existe uma base visual.

1. Identifique o que deve ser mantido.
2. Defina o que deve ser modernizado ou adaptado.
3. Dê contexto de marca e usabilidade.
4. Gere a versão digital.
5. Ajuste componentes, conteúdo e responsividade.

### Fluxo C: marca/site existente -> DESIGN.md -> múltiplas telas
Use quando consistência importa mais que velocidade isolada.

1. Colete referência visual da marca.
2. Sintetize regras em `DESIGN.md`.
3. Gere a tela principal.
4. Gere telas derivadas mantendo o mesmo sistema.
5. Revise coerência entre todas as telas.

### Fluxo D: tela pronta -> iteração -> handoff
Use quando já existe uma tela no Stitch.

1. Liste problemas objetivos.
2. Priorize 3 a 5 mudanças.
3. Faça edições curtas e cumulativas.
4. Revise estados e responsividade.
5. Exporte para o destino apropriado.

## Como escrever prompts melhores para o Stitch

### Modelo curto

```text
Crie uma tela [web/mobile] para [tipo de produto].
Usuário: [quem usa].
Objetivo: [o que precisa acontecer].
Estrutura: [seções/componentes].
Estilo: [direção visual].
Restrições: [branding, acessibilidade, idioma, densidade, etc.].
```

### Modelo completo

```text
Crie uma interface [web/mobile] de alta fidelidade para [produto/cenário].

Usuário principal:
- [perfil do usuário]
- [momento de uso]

Objetivo da tela:
- [resultado esperado]

Ação principal:
- [CTA ou tarefa central]

Conteúdo obrigatório:
- [componente 1]
- [componente 2]
- [componente 3]
- [estado vazio/erro/loading, se relevante]

Estrutura sugerida:
- [header/sidebar/main/detail/footer]

Direção visual:
- [tom da marca]
- [referências de estilo]
- [sensação desejada]

Restrições:
- [cores]
- [grid]
- [idioma]
- [acessibilidade]
- [responsividade]

Gere 3 variações com diferenças reais de hierarquia e layout.
```

## Padrões de pedido úteis

### Para landing page

```text
Crie uma landing page para [produto].
Acima da dobra, a proposta de valor precisa ficar clara em 5 segundos.
Inclua hero, prova social, benefícios, como funciona, FAQ e CTA final.
Estilo: [direção visual].
Tom: [profissional / ousado / amigável / premium].
```

### Para dashboard

```text
Crie um dashboard web para [função].
O usuário precisa identificar rapidamente status, exceções e prioridades.
Inclua sidebar, header, KPIs, gráfico principal, tabela filtrável e painel de detalhes.
Priorize legibilidade e densidade equilibrada.
```

### Para app mobile

```text
Crie um app mobile para [caso de uso].
A navegação deve ser simples para uso com uma mão.
Priorize a ação principal e o estado atual do usuário.
Inclua feedback visual claro, empty state e confirmação de sucesso.
```

### Para redesign com referência

```text
Use esta referência pela estrutura e pelo fluxo, não pela identidade visual.
Redesenhe para uma marca [descrição da marca].
Simplifique a interface, aumente a clareza da hierarquia e modernize os componentes.
```

### Para gerar DESIGN.md inicial

```text
Crie um DESIGN.md para um produto [tipo de produto] com posicionamento [descrição].
Defina princípios visuais, paleta, tipografia, espaçamento, raios, sombras, botões, inputs, cards, tabelas, modais e navegação.
O sistema deve transmitir [sensação desejada].
```

## Exemplos de uso

### Exemplo 1: criar uma tela a partir de uma ideia vaga

Pedido do usuário:

> “Quero uma tela de dashboard para uma plataforma de logística.”

Como agir:

1. Refinar o pedido com objetivo, usuário, decisão principal e estrutura.
2. Entregar um prompt melhor que o original.
3. Sugerir 3 direções distintas.

Resposta esperada do agente:

```text
Crie um dashboard web de alta fidelidade para uma plataforma de logística.
Usuário principal: operador de torre de controle.
Objetivo: identificar atrasos, riscos e entregas críticas em segundos.
Ação principal: priorizar ocorrências e abrir detalhes do pedido.
Estrutura: sidebar, header com busca, KPIs, mapa/lista de rotas, tabela de ocorrências, painel lateral de detalhes.
Estilo: operacional, claro, profissional, focado em legibilidade.
Restrições: contraste forte, densidade média, estados de alerta bem definidos.
Gere 3 variações: uma mais executiva, uma mais operacional e uma mais orientada a mapa.
```

### Exemplo 2: usar um wireframe como base

Pedido do usuário:

> “Transforme esse wireframe em uma interface final.”

Como agir:

1. Descrever o que manter.
2. Definir estilo e marca.
3. Pedir adaptação, não cópia cega.

Resposta esperada do agente:

```text
Use este wireframe como base estrutural.
Preserve a organização das seções e o fluxo principal.
Converta para uma interface web de alta fidelidade para um SaaS B2B.
Estilo: limpo, profissional, moderno, com forte hierarquia tipográfica.
Adicione estados de hover, vazio e loading.
Mostre uma opção mais compacta e outra mais espaçosa.
```

### Exemplo 3: criar um DESIGN.md antes de expandir o projeto

Pedido do usuário:

> “Quero que as próximas telas sigam a mesma linguagem visual.”

Resposta esperada do agente:

```text
Antes de gerar novas telas, crie um DESIGN.md com:
- princípios de marca;
- paleta principal e semântica;
- tipografia para títulos, corpo e rótulos;
- escala de espaçamento;
- botões primário, secundário e ghost;
- inputs, selects, tabelas, cards e modais;
- comportamento de navegação;
- regras de responsividade;
- tom visual geral.
Depois use esse DESIGN.md como base para todas as próximas gerações.
```

### Exemplo 4: pedir uma iteração objetiva

Pedido do usuário:

> “Melhore essa tela.”

Como agir:

Converta o pedido genérico em mudanças verificáveis:

```text
Faça uma nova versão desta tela com as seguintes mudanças:
1. Reduza ruído visual e aumente o espaçamento entre blocos.
2. Dê mais destaque ao CTA principal.
3. Agrupe filtros relacionados.
4. Aumente o contraste da tabela.
5. Mostre uma versão com sidebar e outra com navegação superior.
```

## Boas práticas

- Prefira contexto útil a adjetivos vagos.
- Sempre diga qual decisão o usuário precisa tomar na tela.
- Nomeie seções e componentes explicitamente.
- Peça estados e variantes cedo.
- Use `DESIGN.md` quando o projeto tiver mais de uma ou duas telas.
- Trabalhe em ciclos curtos de geração e revisão.
- Compare alternativas antes de convergir.
- Feche com um resultado acionável, não só com opinião.

## Evite

- Pedidos genéricos sem contexto de produto.
- Feedback subjetivo sem instrução concreta.
- Cópia literal de referência sem adaptação.
- Ignorar responsividade e estados da interface.
- Misturar muitos estilos sem uma direção de marca.
- Expandir para muitas telas antes de estabilizar o sistema visual.

## Saídas preferidas desta skill

Ao usar esta skill, prefira responder com um destes formatos:

1. **Prompt pronto para colar no Stitch**
2. **Conjunto de 3 a 5 iterações recomendadas**
3. **DESIGN.md inicial**
4. **Checklist de revisão da interface**
5. **Mapa de telas/fluxo a gerar**
6. **Plano de handoff para Figma ou código**

## Critério de sucesso

A skill foi bem aplicada quando o resultado:

- reduz ambiguidade antes da geração;
- produz telas mais específicas e menos genéricas;
- mantém consistência entre variações e telas;
- acelera revisão e tomada de decisão;
- facilita exportação e handoff.
