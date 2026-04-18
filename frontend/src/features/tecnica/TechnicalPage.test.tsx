import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';

import { App } from '../../app/App';

const fetchMock = vi.fn();

vi.stubGlobal('fetch', fetchMock);

describe('TechnicalPage', () => {
  beforeEach(() => {
    window.localStorage.clear();
    fetchMock.mockReset();
    fetchMock.mockImplementation(async (input: RequestInfo | URL) => {
      const url = String(input);

      if (url.includes('/api/main/runtime-overview')) {
        return {
          ok: true,
          json: async () => ({
            recommendation: {
              official_runtime: {
                gold: {
                  api_prefix: '/api/current-v2',
                },
              },
            },
          }),
        };
      }

      return {
        ok: true,
        json: async () => ({ ok: true, source: url }),
      };
    });
  });

  it('carrega a area tecnica usando as superficies main e current-v2', async () => {
    render(
      <MemoryRouter
        initialEntries={['/tecnica/operacao']}
        future={{ v7_startTransition: true, v7_relativeSplatPath: true }}
      >
        <App />
      </MemoryRouter>,
    );

    expect(await screen.findByText('Operacao, qualidade e consistencia')).toBeInTheDocument();
    expect(await screen.findByText('Runtime Overview')).toBeInTheDocument();

    const urls = fetchMock.mock.calls.map(([url]) => String(url));
    expect(urls.some((url) => url.includes('/api/main/runtime-overview'))).toBe(true);
    expect(urls.some((url) => url.includes('/api/current-v2/status/'))).toBe(true);
  });
});
