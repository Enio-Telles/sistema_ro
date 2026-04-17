PR: Implementação inicial Fases 05–08

O que foi feito:
- Adicionados testes de integração para `runtime v2`:
  - `tests/test_runtime_v2_agregacao.py`
  - `tests/test_runtime_v2_other_endpoints.py`
- Adicionado checklist operacional: `docs/checklist_phases_05_08.md`
- Adicionado planejamento de implementação: `docs/implementation_todo.md`

Motivação:
- Garantir que os endpoints read-only do `runtime v2` (`agregacao`, `conversao`, `estoque`, `fisconforme`) retornem previews a partir de parquets locais.
- Fornecer checklist e roadmap para as próximas entregas (frontend e execução do pipeline).

Testes:
- Todos os testes novos passam localmente (`pytest tests/test_runtime_v2_agregacao.py` e `pytest tests/test_runtime_v2_other_endpoints.py`).

Notas:
- Branch: `feature/phase-05-08`
- Base sugerida: `main`

Solicito revisão e merge após validação CI.
