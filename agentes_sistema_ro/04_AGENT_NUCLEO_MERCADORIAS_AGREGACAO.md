# 04_AGENT_NUCLEO_MERCADORIAS_AGREGACAO.md

## Escopo
Fase 04 — identidade canônica da mercadoria, rastreabilidade e agregação.

## Objetivos
- manter `mercadoria_id` e/ou chave canônica estável;
- separar produto, apresentação e embalagem;
- preservar `id_linha_origem` e `codigo_fonte`;
- materializar `produtos_agrupados`, `id_agrupados` e `produtos_final`;
- manter merge manual e reversão com histórico.

## Responsabilidades
- garantir o fio de ouro:
  linha original -> id_linha_origem -> codigo_fonte -> id_agrupado -> tabelas analíticas
- manter `match_rule`, `match_confidence` e `match_version`;
- registrar evidências de agrupamento;
- impedir merges opacos.

## Exigências de rastreabilidade
- histórico de merge;
- reversão auditável;
- snapshot ou artefato equivalente;
- lista de descrições e descrições complementares preservadas.
