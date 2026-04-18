import { Link, NavLink, Outlet } from 'react-router-dom';

interface AppShellProps {
  cnpj: string;
  onCnpjChange: (value: string) => void;
}

export function AppShell({ cnpj, onCnpjChange }: AppShellProps) {
  return (
    <div className="app-shell">
      <aside className="side-nav">
        <Link className="brand" to="/usuario/analise-fiscal/estoque">
          <span className="brand-mark">SR</span>
          <div>
            <strong>sistema_ro</strong>
            <span>Frontend operacional</span>
          </div>
        </Link>

        <div className="nav-section">
          <span className="nav-heading">Area do Usuario</span>
          <NavLink to="/usuario/efd" className="nav-link">
            EFD
          </NavLink>
          <NavLink to="/usuario/documentos-fiscais" className="nav-link">
            Documentos Fiscais
          </NavLink>
          <NavLink to="/usuario/analise-fiscal/estoque" className="nav-link">
            Analise Fiscal
          </NavLink>
        </div>

        <div className="nav-section">
          <span className="nav-heading">Area Tecnica</span>
          <NavLink to="/tecnica/operacao" className="nav-link">
            Operacao e Qualidade
          </NavLink>
        </div>
      </aside>

      <main className="content-area">
        <header className="topbar">
          <div>
            <p className="eyebrow">Contexto operacional</p>
            <h1 className="topbar-title">Fiscal Parquet Analyzer</h1>
          </div>

          <label className="field field-inline">
            <span>CNPJ</span>
            <input
              value={cnpj}
              onChange={(event) => onCnpjChange(event.target.value.replace(/\D/g, '').slice(0, 14))}
              placeholder="00000000000000"
            />
          </label>
        </header>

        <Outlet />
      </main>
    </div>
  );
}
