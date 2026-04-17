export type DatasetEstoque =
  | 'mov_estoque'
  | 'aba_mensal'
  | 'aba_anual'
  | 'aba_periodos'
  | 'estoque_resumo'
  | 'estoque_alertas';

export type SortDirection = 'asc' | 'desc';

export interface ColumnDef {
  name: string;
  dtype: string;
}

export interface TableResponse {
  cnpj: string;
  dataset: DatasetEstoque;
  exists: boolean;
  offset: number;
  limit: number;
  rows_total: number;
  columns: ColumnDef[];
  items: Record<string, unknown>[];
  sort_applied: { column: string; direction: SortDirection } | null;
  filters_applied: Array<{ column: string; value: string; mode: string }>;
  search_applied: { term: string; columns: string[] } | null;
}

export interface TableState {
  search: string;
  sortBy: string;
  sortDir: SortDirection;
  columns: string[];
  filters: Record<string, string>;
  offset: number;
  limit: number;
}

export interface EstoqueTab {
  id: string;
  title: string;
  dataset: DatasetEstoque;
  state: TableState;
  locked?: boolean;
}

export interface OverviewPreview {
  cnpj: string;
  layer: string;
  name: string;
  exists: boolean;
  rows: number;
  items: Record<string, unknown>[];
}

export interface EstoqueOverviewResponse {
  cnpj: string;
  mov_estoque: OverviewPreview;
  aba_mensal: OverviewPreview;
  aba_anual: OverviewPreview;
  aba_periodos: OverviewPreview;
  estoque_resumo: OverviewPreview;
  estoque_alertas: OverviewPreview;
}

export interface EstoqueQualityResponse {
  cnpj: string;
  resumo: {
    total_movimentos: number;
    linhas_estoque_inicial: number;
    linhas_estoque_final: number;
    linhas_com_periodo: number;
    divergencia_estoque_declarado_total: number;
    divergencia_estoque_calculado_total: number;
  };
  mov_estoque: OverviewPreview;
  aba_anual: OverviewPreview;
  estoque_alertas: OverviewPreview;
}

export interface GoldConsistencyResponse {
  cnpj: string;
  ok: boolean;
  coherence: {
    movimentos_com_saldo_negativo: number;
  };
  inventory_contract: {
    linhas_estoque_final_sem_qtd_decl_final_audit: number;
  };
  fiscal: {
    icms_entr_desacob_total: number;
    icms_saidas_desac_total: number;
    icms_estoque_desac_total: number;
  };
}
