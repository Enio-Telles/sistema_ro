import { startTransition, useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';

import { DataTable } from '../../components/DataTable';
import {
  buildEstoqueExportUrl,
  fetchEstoqueDiagnostics,
  fetchEstoqueOverview,
  fetchEstoqueTable,
} from '../../lib/api';
import { loadJson, saveJson } from '../../lib/storage';
import type {
  DatasetEstoque,
  EstoqueOverviewResponse,
  EstoqueQualityResponse,
  EstoqueTab,
  GoldConsistencyResponse,
  TableResponse,
  TableState,
} from '../../lib/types';

interface EstoquePageProps {
  cnpj: string;
}

interface EstoqueDiagnostics {
  quality: EstoqueQualityResponse;
  consistency: GoldConsistencyResponse;
}

const STORAGE_PREFIX = 'sistema_ro.frontend.estoque.tabs';

const DEFAULT_TABLE_STATE: TableState = {
  search: '',
  sortBy: '',
  sortDir: 'asc',
  columns: [],
  filters: {},
  offset: 0,
  limit: 25,
};

const BASE_TABS: Array<{ id: string; title: string; dataset: DatasetEstoque }> = [
  { id: 'movimentacao', title: 'Movimentacao', dataset: 'mov_estoque' },
  { id: 'mensal', title: 'Mensal', dataset: 'aba_mensal' },
  { id: 'anual', title: 'Anual', dataset: 'aba_anual' },
  { id: 'periodos', title: 'Periodos', dataset: 'aba_periodos' },
  { id: 'resumo', title: 'Resumo', dataset: 'estoque_resumo' },
  { id: 'alertas', title: 'Alertas', dataset: 'estoque_alertas' },
];

function buildInitialTabs(cnpj: string): EstoqueTab[] {
  const saved = loadJson<EstoqueTab[]>(`${STORAGE_PREFIX}.${cnpj}`, []);
  if (saved.length > 0) {
    return saved;
  }
  return BASE_TABS.map((tab) => ({
    id: tab.id,
    title: tab.title,
    dataset: tab.dataset,
    state: { ...DEFAULT_TABLE_STATE },
    locked: true,
  }));
}

function serializeActiveTab(tab: EstoqueTab | undefined): string {
  if (!tab) {
    return '';
  }
  return encodeURIComponent(
    JSON.stringify({
      id: tab.id,
      dataset: tab.dataset,
      title: tab.title,
      state: tab.state,
    }),
  );
}

function parseActiveTab(serialized: string | null): Partial<EstoqueTab> | null {
  if (!serialized) {
    return null;
  }
  try {
    return JSON.parse(decodeURIComponent(serialized)) as Partial<EstoqueTab>;
  } catch {
    return null;
  }
}

function formatNumber(value: number): string {
  return new Intl.NumberFormat('pt-BR', {
    maximumFractionDigits: 2,
  }).format(value);
}

export function EstoquePage({ cnpj }: EstoquePageProps) {
  const [searchParams, setSearchParams] = useSearchParams();
  const [tabs, setTabs] = useState<EstoqueTab[]>(() => buildInitialTabs(cnpj));
  const [overview, setOverview] = useState<EstoqueOverviewResponse | null>(null);
  const [diagnostics, setDiagnostics] = useState<EstoqueDiagnostics | null>(null);
  const [tableResponse, setTableResponse] = useState<TableResponse | null>(null);
  const [loadingOverview, setLoadingOverview] = useState(true);
  const [loadingTable, setLoadingTable] = useState(true);
  const [tableError, setTableError] = useState<string | null>(null);
  const [overviewError, setOverviewError] = useState<string | null>(null);

  useEffect(() => {
    setTabs(buildInitialTabs(cnpj));
  }, [cnpj]);

  const serializedState = searchParams.get('viewState');
  const queryTabId = searchParams.get('tab');

  useEffect(() => {
    const fromQuery = parseActiveTab(serializedState);
    if (!fromQuery?.id) {
      return;
    }
    setTabs((currentTabs) =>
      currentTabs.map((tab) =>
        tab.id === fromQuery.id && fromQuery.state
          ? {
              ...tab,
              title: fromQuery.title ?? tab.title,
              state: {
                ...tab.state,
                ...fromQuery.state,
              },
            }
          : tab,
      ),
    );
  }, [serializedState]);

  const activeTab = tabs.find((tab) => tab.id === queryTabId) ?? tabs[0];

  useEffect(() => {
    saveJson(`${STORAGE_PREFIX}.${cnpj}`, tabs);
  }, [cnpj, tabs]);

  useEffect(() => {
    if (!activeTab) {
      return;
    }

    const nextParams = new URLSearchParams(searchParams);
    const serialized = serializeActiveTab(activeTab);
    if (nextParams.get('tab') === activeTab.id && nextParams.get('viewState') === serialized) {
      return;
    }

    nextParams.set('tab', activeTab.id);
    nextParams.set('viewState', serialized);
    setSearchParams(nextParams, { replace: true });
  }, [activeTab, searchParams, setSearchParams]);

  useEffect(() => {
    let cancelled = false;

    async function loadOverview() {
      setLoadingOverview(true);
      setOverviewError(null);
      try {
        const [overviewPayload, diagnosticsPayload] = await Promise.all([
          fetchEstoqueOverview(cnpj),
          fetchEstoqueDiagnostics(cnpj),
        ]);
        if (!cancelled) {
          setOverview(overviewPayload);
          setDiagnostics(diagnosticsPayload);
        }
      } catch (err) {
        if (!cancelled) {
          setOverviewError(
            err instanceof Error ? err.message : 'Falha ao carregar visao geral e diagnosticos do estoque.',
          );
        }
      } finally {
        if (!cancelled) {
          setLoadingOverview(false);
        }
      }
    }

    void loadOverview();

    return () => {
      cancelled = true;
    };
  }, [cnpj]);

  useEffect(() => {
    if (!activeTab) {
      return;
    }

    let cancelled = false;

    async function loadTable() {
      setLoadingTable(true);
      setTableError(null);
      try {
        const payload = await fetchEstoqueTable(cnpj, activeTab.dataset, activeTab.state);
        if (!cancelled) {
          setTableResponse(payload);
        }
      } catch (err) {
        if (!cancelled) {
          setTableError(err instanceof Error ? err.message : 'Falha ao carregar a tabela operacional.');
        }
      } finally {
        if (!cancelled) {
          setLoadingTable(false);
        }
      }
    }

    void loadTable();

    return () => {
      cancelled = true;
    };
  }, [activeTab, cnpj]);

  const updateActiveTab = (patch: Partial<TableState>) => {
    if (!activeTab) {
      return;
    }
    startTransition(() => {
      setTabs((currentTabs) =>
        currentTabs.map((tab) =>
          tab.id === activeTab.id
            ? {
                ...tab,
                state: {
                  ...tab.state,
                  ...patch,
                },
              }
            : tab,
        ),
      );
    });
  };

  const activateTab = (tabId: string) => {
    const nextParams = new URLSearchParams(searchParams);
    nextParams.set('tab', tabId);
    setSearchParams(nextParams, { replace: false });
  };

  const cloneActiveTab = () => {
    if (!activeTab) {
      return;
    }
    const nextId = `${activeTab.id}-detalhe-${tabs.filter((tab) => tab.id.startsWith(activeTab.id)).length + 1}`;
    const clonedTab: EstoqueTab = {
      ...activeTab,
      id: nextId,
      title: `${activeTab.title} · Destaque`,
      locked: false,
      state: {
        ...activeTab.state,
      },
    };
    startTransition(() => {
      setTabs((currentTabs) => [...currentTabs, clonedTab]);
    });
    activateTab(nextId);
  };

  const closeTab = (tabId: string) => {
    const tab = tabs.find((item) => item.id === tabId);
    if (!tab || tab.locked) {
      return;
    }

    const remainingTabs = tabs.filter((item) => item.id !== tabId);
    setTabs(remainingTabs);
    activateTab(remainingTabs[0]?.id ?? BASE_TABS[0].id);
  };

  const overviewCards = overview
    ? [
        overview.mov_estoque,
        overview.aba_mensal,
        overview.aba_anual,
        overview.aba_periodos,
        overview.estoque_resumo,
        overview.estoque_alertas,
      ]
    : [];

  const diagnosisCards = diagnostics
    ? [
        {
          label: 'Movimentos',
          value: formatNumber(diagnostics.quality.resumo.total_movimentos),
        },
        {
          label: 'Divergencia declarada',
          value: formatNumber(diagnostics.quality.resumo.divergencia_estoque_declarado_total),
        },
        {
          label: 'Saldo negativo',
          value: formatNumber(diagnostics.consistency.coherence.movimentos_com_saldo_negativo),
        },
        {
          label: 'Saidas desacob',
          value: formatNumber(diagnostics.consistency.fiscal.icms_saidas_desac_total),
        },
        {
          label: 'Estoque final sem qtd auditavel',
          value: formatNumber(
            diagnostics.consistency.inventory_contract.linhas_estoque_final_sem_qtd_decl_final_audit,
          ),
        },
        {
          label: 'Alertas materializados',
          value: formatNumber(overview?.estoque_alertas.rows ?? 0),
        },
      ]
    : [];

  return (
    <section className="estoque-page">
      <div className="page-heading">
        <div>
          <p className="eyebrow">Area do Usuario · Analise Fiscal</p>
          <h1>Estoque</h1>
        </div>
      </div>

      <div className="status-card">
        O primeiro fluxo funcional do frontend foi concentrado em Estoque para aproveitar a trilha backend mais madura, sem misturar detalhes tecnicos na navegacao principal.
      </div>

      {loadingOverview ? <div className="status-card">Carregando panorama dos datasets de estoque...</div> : null}
      {overviewError ? <div className="status-card status-error">{overviewError}</div> : null}

      <section className="summary-section">
        <div className="section-heading">
          <p className="eyebrow">Leitura rapida</p>
          <h2>Resumo analitico do estoque</h2>
        </div>
        <div className="summary-grid">
          {diagnosisCards.map((card) => (
            <article key={card.label} className="summary-card">
              <span className="summary-label">{card.label}</span>
              <strong>{card.value}</strong>
            </article>
          ))}
        </div>
      </section>

      <section className="summary-section">
        <div className="section-heading">
          <p className="eyebrow">Datasets em uso</p>
          <h2>Disponibilidade por visao</h2>
        </div>
        <div className="summary-grid">
          {overviewCards.map((card) => (
            <article key={card.name} className="summary-card">
              <span className="summary-label">{card.name}</span>
              <strong>{card.exists ? `${card.rows} linhas` : 'Parquet ausente'}</strong>
            </article>
          ))}
        </div>
      </section>

      <div className="tab-strip">
        {tabs.map((tab) => (
          <div key={tab.id} className={`tab-chip ${activeTab?.id === tab.id ? 'tab-chip-active' : ''}`}>
            <button type="button" onClick={() => activateTab(tab.id)}>
              {tab.title}
            </button>
            {!tab.locked ? (
              <button
                type="button"
                className="tab-close"
                aria-label={`Fechar ${tab.title}`}
                onClick={() => closeTab(tab.id)}
              >
                ×
              </button>
            ) : null}
          </div>
        ))}
      </div>

      <DataTable
        response={tableResponse}
        state={activeTab?.state ?? DEFAULT_TABLE_STATE}
        loading={loadingTable}
        error={tableError}
        onStateChange={updateActiveTab}
        onCloneTab={cloneActiveTab}
        exportUrl={activeTab ? buildEstoqueExportUrl(cnpj, activeTab.dataset, activeTab.state) : '#'}
      />
    </section>
  );
}
