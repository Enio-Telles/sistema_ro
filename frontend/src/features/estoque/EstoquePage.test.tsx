import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';

import { App } from '../../app/App';

const fetchMock = vi.fn();

vi.stubGlobal('fetch', fetchMock);

describe('EstoquePage', () => {
  beforeEach(() => {
    window.localStorage.clear();
    fetchMock.mockReset();
    fetchMock
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          cnpj: '12345678000199',
          mov_estoque: { name: 'mov_estoque', exists: true, rows: 3, items: [], cnpj: '123', layer: 'gold' },
          aba_mensal: { name: 'aba_mensal', exists: true, rows: 2, items: [], cnpj: '123', layer: 'gold' },
          aba_anual: { name: 'aba_anual', exists: true, rows: 1, items: [], cnpj: '123', layer: 'gold' },
          aba_periodos: { name: 'aba_periodos', exists: true, rows: 1, items: [], cnpj: '123', layer: 'gold' },
          estoque_resumo: { name: 'estoque_resumo', exists: true, rows: 1, items: [], cnpj: '123', layer: 'gold' },
          estoque_alertas: { name: 'estoque_alertas', exists: true, rows: 1, items: [], cnpj: '123', layer: 'gold' },
        }),
      })
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          cnpj: '12345678000199',
          resumo: {
            total_movimentos: 10,
            linhas_estoque_inicial: 1,
            linhas_estoque_final: 1,
            linhas_com_periodo: 8,
            divergencia_estoque_declarado_total: 2.5,
            divergencia_estoque_calculado_total: 1.5,
          },
          mov_estoque: { name: 'mov_estoque', exists: true, rows: 3, items: [], cnpj: '123', layer: 'gold' },
          aba_anual: { name: 'aba_anual', exists: true, rows: 1, items: [], cnpj: '123', layer: 'gold' },
          estoque_alertas: { name: 'estoque_alertas', exists: true, rows: 1, items: [], cnpj: '123', layer: 'gold' },
        }),
      })
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          cnpj: '12345678000199',
          ok: false,
          coherence: {
            movimentos_com_saldo_negativo: 2,
          },
          inventory_contract: {
            linhas_estoque_final_sem_qtd_decl_final_audit: 1,
          },
          fiscal: {
            icms_entr_desacob_total: 0,
            icms_saidas_desac_total: 12.5,
            icms_estoque_desac_total: 4,
          },
        }),
      })
      .mockResolvedValue({
        ok: true,
        json: async () => ({
          cnpj: '12345678000199',
          dataset: 'mov_estoque',
          exists: true,
          offset: 0,
          limit: 25,
          rows_total: 1,
          columns: [
            { name: 'id_agregado', dtype: 'String' },
            { name: 'produto', dtype: 'String' },
          ],
          items: [{ id_agregado: 'A1', produto: 'Arroz' }],
          sort_applied: null,
          filters_applied: [],
          search_applied: null,
        }),
      });
  });

  it('destaca a tabela em nova aba e persiste o estado local', async () => {
    const user = userEvent.setup();

    render(
      <MemoryRouter
        initialEntries={['/usuario/analise-fiscal/estoque']}
        future={{ v7_startTransition: true, v7_relativeSplatPath: true }}
      >
        <App />
      </MemoryRouter>,
    );

    await screen.findByText('Movimentacao');
    expect(await screen.findByText('Resumo analitico do estoque')).toBeInTheDocument();
    expect(screen.getByText('10')).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Destacar em nova aba' }));

    expect(await screen.findByText('Movimentacao · Destaque')).toBeInTheDocument();

    await waitFor(() => {
      const savedTabs = window.localStorage.getItem('sistema_ro.frontend.estoque.tabs.12345678000199');
      expect(savedTabs).toContain('Movimentacao');
      expect(savedTabs).toContain('Destaque');
    });
  });
});
