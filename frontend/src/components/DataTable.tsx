import { useDeferredValue } from 'react';

import type { TableResponse, TableState } from '../lib/types';

interface DataTableProps {
  response: TableResponse | null;
  state: TableState;
  loading: boolean;
  error: string | null;
  onStateChange: (patch: Partial<TableState>) => void;
  onCloneTab: () => void;
  exportUrl: string;
}

export function DataTable({
  response,
  state,
  loading,
  error,
  onStateChange,
  onCloneTab,
  exportUrl,
}: DataTableProps) {
  const deferredSearch = useDeferredValue(state.search);
  const columns = response?.columns ?? [];
  const availableColumnNames = columns.map((column) => column.name);
  const visibleColumns = state.columns.length > 0 ? state.columns : availableColumnNames;
  const totalPages = response ? Math.max(1, Math.ceil(response.rows_total / state.limit)) : 1;
  const currentPage = Math.floor(state.offset / state.limit) + 1;

  const toggleColumn = (columnName: string) => {
    const nextColumns = state.columns.includes(columnName)
      ? state.columns.filter((column) => column !== columnName)
      : [...state.columns, columnName];
    onStateChange({ columns: nextColumns });
  };

  const updateFilter = (columnName: string, value: string) => {
    onStateChange({
      filters: {
        ...state.filters,
        [columnName]: value,
      },
      offset: 0,
    });
  };

  return (
    <section className="data-panel">
      <div className="data-toolbar">
        <label className="field">
          <span>Busca textual</span>
          <input
            value={state.search}
            onChange={(event) => onStateChange({ search: event.target.value, offset: 0 })}
            placeholder="Pesquisar no dataset atual"
          />
        </label>

        <label className="field">
          <span>Ordenar por</span>
          <select
            value={state.sortBy}
            onChange={(event) => onStateChange({ sortBy: event.target.value, offset: 0 })}
          >
            <option value="">Sem ordenacao</option>
            {availableColumnNames.map((columnName) => (
              <option key={columnName} value={columnName}>
                {columnName}
              </option>
            ))}
          </select>
        </label>

        <label className="field field-compact">
          <span>Direcao</span>
          <select
            value={state.sortDir}
            onChange={(event) =>
              onStateChange({ sortDir: event.target.value as TableState['sortDir'], offset: 0 })
            }
          >
            <option value="asc">Ascendente</option>
            <option value="desc">Descendente</option>
          </select>
        </label>

        <label className="field field-compact">
          <span>Linhas</span>
          <select
            value={state.limit}
            onChange={(event) => onStateChange({ limit: Number(event.target.value), offset: 0 })}
          >
            {[25, 50, 100].map((size) => (
              <option key={size} value={size}>
                {size}
              </option>
            ))}
          </select>
        </label>

        <div className="toolbar-actions">
          <a className="button button-secondary" href={exportUrl}>
            Exportar CSV
          </a>
          <button type="button" className="button" onClick={onCloneTab}>
            Destacar em nova aba
          </button>
        </div>
      </div>

      <div className="column-manager">
        <span className="section-label">Colunas visiveis</span>
        <div className="checkbox-grid">
          {availableColumnNames.map((columnName) => {
            const checked = visibleColumns.includes(columnName);
            return (
              <label key={columnName} className="checkbox-chip">
                <input
                  type="checkbox"
                  checked={checked}
                  onChange={() => toggleColumn(columnName)}
                />
                <span>{columnName}</span>
              </label>
            );
          })}
        </div>
      </div>

      <div className="filter-grid">
        {visibleColumns.map((columnName) => (
          <label key={columnName} className="field">
            <span>Filtro: {columnName}</span>
            <input
              value={state.filters[columnName] ?? ''}
              onChange={(event) => updateFilter(columnName, event.target.value)}
              placeholder={`Filtrar ${columnName}`}
            />
          </label>
        ))}
      </div>

      <div className="table-meta">
        <span>
          Busca aplicada: <strong>{deferredSearch || 'sem busca textual'}</strong>
        </span>
        <span>
          Linhas encontradas: <strong>{response?.rows_total ?? 0}</strong>
        </span>
      </div>

      {error ? <div className="status-card status-error">{error}</div> : null}
      {loading ? <div className="status-card">Carregando tabela operacional...</div> : null}
      {!loading && response && !response.exists ? (
        <div className="status-card">
          O parquet desta visao ainda nao existe para o CNPJ informado. A tela permanece utilizavel com estado vazio consistente.
        </div>
      ) : null}

      {!loading && response?.exists ? (
        <div className="table-shell">
          <table>
            <thead>
              <tr>
                {visibleColumns.map((columnName) => (
                  <th key={columnName}>{columnName}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {response.items.length === 0 ? (
                <tr>
                  <td colSpan={Math.max(visibleColumns.length, 1)} className="empty-cell">
                    Nenhuma linha encontrada para o recorte atual.
                  </td>
                </tr>
              ) : (
                response.items.map((row, rowIndex) => (
                  <tr key={`${rowIndex}-${String(row[visibleColumns[0]] ?? rowIndex)}`}>
                    {visibleColumns.map((columnName) => (
                      <td key={columnName}>{String(row[columnName] ?? '')}</td>
                    ))}
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      ) : null}

      <div className="pagination-bar">
        <button
          type="button"
          className="button button-secondary"
          disabled={currentPage <= 1}
          onClick={() => onStateChange({ offset: Math.max(0, state.offset - state.limit) })}
        >
          Pagina anterior
        </button>
        <span>
          Pagina <strong>{currentPage}</strong> de <strong>{totalPages}</strong>
        </span>
        <button
          type="button"
          className="button button-secondary"
          disabled={!response || state.offset + state.limit >= response.rows_total}
          onClick={() => onStateChange({ offset: state.offset + state.limit })}
        >
          Proxima pagina
        </button>
      </div>
    </section>
  );
}
