import { useEffect, useState } from 'react';

import { fetchTechnicalSnapshot } from '../../lib/api';

interface TechnicalPageProps {
  cnpj: string;
}

export function TechnicalPage({ cnpj }: TechnicalPageProps) {
  const [cards, setCards] = useState<Record<string, unknown>[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      setLoading(true);
      setError(null);
      try {
        const payload = await fetchTechnicalSnapshot(cnpj);
        if (!cancelled) {
          setCards(payload);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : 'Falha ao carregar a area tecnica.');
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void load();

    return () => {
      cancelled = true;
    };
  }, [cnpj]);

  return (
    <section className="technical-page">
      <div className="page-heading">
        <div>
          <p className="eyebrow">Area Tecnica</p>
          <h1>Operacao, qualidade e consistencia</h1>
        </div>
      </div>

      {loading ? <div className="status-card">Carregando diagnostico tecnico...</div> : null}
      {error ? <div className="status-card status-error">{error}</div> : null}

      <div className="technical-grid">
        {cards.map((card) => (
          <article key={String(card.title)} className="technical-card">
            <h2>{String(card.title)}</h2>
            <pre>{JSON.stringify(card.payload, null, 2)}</pre>
          </article>
        ))}
      </div>
    </section>
  );
}
