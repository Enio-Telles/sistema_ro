import type {
  DatasetEstoque,
  EstoqueOverviewResponse,
  EstoqueQualityResponse,
  GoldConsistencyResponse,
  TableResponse,
  TableState,
} from './types';

const API_BASE_URL =
  (import.meta.env.VITE_API_BASE_URL as string | undefined)?.replace(/\/$/, '') ??
  'http://127.0.0.1:8000';

async function fetchJson<T>(path: string): Promise<T> {
  const response = await fetch(`${API_BASE_URL}${path}`);
  if (!response.ok) {
    throw new Error(`Falha ao carregar ${path}: ${response.status}`);
  }
  return (await response.json()) as T;
}

export function buildTableQuery(state: TableState): string {
  const params = new URLSearchParams();
  params.set('offset', String(state.offset));
  params.set('limit', String(state.limit));

  if (state.search) {
    params.set('search', state.search);
  }
  if (state.sortBy) {
    params.set('sort_by', state.sortBy);
    params.set('sort_dir', state.sortDir);
  }
  if (state.columns.length > 0) {
    params.set('columns', state.columns.join(','));
  }

  for (const [column, value] of Object.entries(state.filters)) {
    if (value.trim()) {
      params.set(`filter__${column}`, value);
    }
  }

  return params.toString();
}

export async function fetchEstoqueOverview(cnpj: string): Promise<EstoqueOverviewResponse> {
  return fetchJson<EstoqueOverviewResponse>(`/api/current-v2/estoque/${cnpj}/overview`);
}

export async function fetchEstoqueDiagnostics(
  cnpj: string,
): Promise<{ quality: EstoqueQualityResponse; consistency: GoldConsistencyResponse }> {
  const [quality, consistency] = await Promise.all([
    fetchJson<EstoqueQualityResponse>(`/api/current-v2/estoque/${cnpj}/quality`),
    fetchJson<GoldConsistencyResponse>(`/api/current-v2/gold/${cnpj}`),
  ]);
  return { quality, consistency };
}

export async function fetchEstoqueTable(
  cnpj: string,
  dataset: DatasetEstoque,
  state: TableState,
): Promise<TableResponse> {
  const query = buildTableQuery(state);
  const suffix = query ? `?${query}` : '';
  return fetchJson<TableResponse>(`/api/current-v2/estoque/${cnpj}/tabelas/${dataset}${suffix}`);
}

export function buildEstoqueExportUrl(cnpj: string, dataset: DatasetEstoque, state: TableState): string {
  const query = buildTableQuery(state);
  const suffix = query ? `?${query}` : '';
  return `${API_BASE_URL}/api/current-v2/estoque/${cnpj}/tabelas/${dataset}/export${suffix}`;
}

export async function fetchTechnicalSnapshot(cnpj: string): Promise<Record<string, unknown>[]> {
  const [runtimeOverview, status, pipelineStatus, consistency, quality] = await Promise.all([
    fetchJson(`/api/main/runtime-overview`),
    fetchJson(`/api/current-v2/status/${cnpj}`),
    fetchJson(`/api/current-v2/pipeline/${cnpj}/status`),
    fetchJson(`/api/current-v2/gold/${cnpj}`),
    fetchJson(`/api/current-v2/estoque/${cnpj}/quality`),
  ]);

  return [
    { title: 'Runtime Overview', payload: runtimeOverview },
    { title: 'Status do CNPJ', payload: status },
    { title: 'Status do Pipeline', payload: pipelineStatus },
    { title: 'Consistencia Gold', payload: consistency },
    { title: 'Qualidade do Estoque', payload: quality },
  ];
}
