interface PlaceholderPageProps {
  title: string;
  description: string;
}

export function PlaceholderPage({ title, description }: PlaceholderPageProps) {
  return (
    <section className="placeholder-page">
      <div className="page-heading">
        <div>
          <p className="eyebrow">Área do Usuário</p>
          <h1>{title}</h1>
        </div>
      </div>

      <div className="status-card">
        <strong>Escopo desta etapa:</strong> {description}
      </div>
      <div className="status-card">
        Esta área já aparece na navegação canônica para deixar explícita a separação entre escrituração, documentos fiscais e análise fiscal, sem simular módulos ainda não implementados.
      </div>
    </section>
  );
}
