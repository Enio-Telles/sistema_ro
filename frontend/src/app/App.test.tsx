import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';

import { App } from './App';

const fetchMock = vi.fn();

vi.stubGlobal('fetch', fetchMock);

describe('App', () => {
  beforeEach(() => {
    window.localStorage.clear();
    fetchMock.mockReset();
    fetchMock
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          cnpj: '12345678000199',
          mov_estoque: { name: 'mov_estoque', exists: false, rows: 0, items: [], cnpj: '123', layer: 'gold' },
          aba_mensal: { name: 'aba_mensal', exists: false, rows: 0, items: [], cnpj: '123', layer: 'gold' },
          aba_anual: { name: 'aba_anual', exists: false, rows: 0, items: [], cnpj: '123', layer: 'gold' },
          aba_periodos: { name: 'aba_periodos', exists: false, rows: 0, items: [], cnpj: '123', layer: 'gold' },
          estoque_resumo: { name: 'estoque_resumo', exists: false, rows: 0, items: [], cnpj: '123', layer: 'gold' },
          estoque_alertas: { name: 'estoque_alertas', exists: false, rows: 0, items: [], cnpj: '123', layer: 'gold' },
        }),
      })
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          cnpj: '12345678000199',
          resumo: {
            total_movimentos: 0,
            linhas_estoque_inicial: 0,
            linhas_estoque_final: 0,
            linhas_com_periodo: 0,
            divergencia_estoque_declarado_total: 0,
            divergencia_estoque_calculado_total: 0,
          },
          mov_estoque: { name: 'mov_estoque', exists: false, rows: 0, items: [], cnpj: '123', layer: 'gold' },
          aba_anual: { name: 'aba_anual', exists: false, rows: 0, items: [], cnpj: '123', layer: 'gold' },
          estoque_alertas: { name: 'estoque_alertas', exists: false, rows: 0, items: [], cnpj: '123', layer: 'gold' },
        }),
      })
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          cnpj: '12345678000199',
          ok: true,
          coherence: {
            movimentos_com_saldo_negativo: 0,
          },
          inventory_contract: {
            linhas_estoque_final_sem_qtd_decl_final_audit: 0,
          },
          fiscal: {
            icms_entr_desacob_total: 0,
            icms_saidas_desac_total: 0,
            icms_estoque_desac_total: 0,
          },
        }),
      })
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          cnpj: '12345678000199',
          dataset: 'mov_estoque',
          columns: [],
          rows_total: 0,
          offset: 0,
          limit: 25,
          exists: false,
          items: [],
          sort_applied: null,
          filters_applied: [],
          search_applied: null,
        }),
      });
  });

  it('separa Area do Usuario e Area Tecnica na shell principal', async () => {
    render(
      <MemoryRouter
        initialEntries={['/usuario/analise-fiscal/estoque']}
        future={{ v7_startTransition: true, v7_relativeSplatPath: true }}
      >
        <App />
      </MemoryRouter>,
    );

    expect(screen.getByText('Area do Usuario')).toBeInTheDocument();
    expect(screen.getByText('Area Tecnica')).toBeInTheDocument();
    expect(screen.getByText('EFD')).toBeInTheDocument();
    expect(screen.getByText('Documentos Fiscais')).toBeInTheDocument();
    expect(screen.getByText('Analise Fiscal')).toBeInTheDocument();
    expect(await screen.findByText('Estoque')).toBeInTheDocument();
  });
});
