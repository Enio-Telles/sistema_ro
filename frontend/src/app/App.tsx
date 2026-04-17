import { useEffect, useState } from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';

import { PlaceholderPage } from '../features/placeholders/PlaceholderPage';
import { AppShell } from '../features/shell/AppShell';
import { EstoquePage } from '../features/estoque/EstoquePage';
import { TechnicalPage } from '../features/tecnica/TechnicalPage';
import { loadJson, saveJson } from '../lib/storage';

const STORAGE_CNPJ_KEY = 'sistema_ro.frontend.cnpj';
const DEFAULT_CNPJ = '12345678000199';

export function App() {
  const [cnpj, setCnpj] = useState<string>(() => loadJson(STORAGE_CNPJ_KEY, DEFAULT_CNPJ));

  useEffect(() => {
    saveJson(STORAGE_CNPJ_KEY, cnpj);
  }, [cnpj]);

  return (
    <Routes>
      <Route path="/" element={<AppShell cnpj={cnpj} onCnpjChange={setCnpj} />}>
        <Route index element={<Navigate to="/usuario/analise-fiscal/estoque" replace />} />
        <Route
          path="usuario/efd"
          element={
            <PlaceholderPage
              title="EFD"
              description="A area de escrituracao ja esta preservada na navegacao canonica, mas a implementacao funcional sera aberta depois que o primeiro modulo de analise fiscal estiver estabilizado."
            />
          }
        />
        <Route
          path="usuario/documentos-fiscais"
          element={
            <PlaceholderPage
              title="Documentos Fiscais"
              description="Notas fiscais, CT-e, Fisconforme e Fronteira continuarao separados da area pura de EFD e da area analitica. Nesta etapa, a shell exibe apenas o placeholder canonico."
            />
          }
        />
        <Route path="usuario/analise-fiscal/estoque" element={<EstoquePage cnpj={cnpj} />} />
        <Route path="tecnica/operacao" element={<TechnicalPage cnpj={cnpj} />} />
      </Route>
    </Routes>
  );
}
