import os
import sys
import requests
import zipfile


def read_token():
    token = None
    try:
        with open('.env', 'r', encoding='utf-8') as f:
            for line in f:
                if line.strip().startswith('GITHUB_TOKEN'):
                    parts = line.split('=', 1)
                    if len(parts) > 1:
                        token = parts[1].strip()
                        break
    except FileNotFoundError:
        pass
    if not token:
        print('GITHUB_TOKEN not found in .env', file=sys.stderr)
        sys.exit(1)
    return token


def download_run(runid, token):
    session = requests.Session()
    headers_base = {'User-Agent': 'sistema_ro-agent'}
    out_dir = os.path.join('ci_logs', f'run-{runid}')
    out_zip = os.path.join('ci_logs', f'run-{runid}.zip')
    os.makedirs(out_dir, exist_ok=True)

    for auth_scheme in (f'token {token}', f'Bearer {token}'):
        headers = headers_base.copy()
        headers['Authorization'] = auth_scheme
        try:
            r = session.get(f'https://api.github.com/repos/Enio-Telles/sistema_ro/actions/runs/{runid}/logs', headers=headers, allow_redirects=False, timeout=30)
            print(f'run {runid} initial status: {r.status_code}')
            if 'location' in r.headers:
                loc = r.headers['location']
                print(f'run {runid} redirect to: {loc}')
                r2 = session.get(loc, stream=True, timeout=120)
                print(f'run {runid} download status: {r2.status_code}')
                if r2.status_code == 200:
                    with open(out_zip, 'wb') as fh:
                        for chunk in r2.iter_content(1024 * 1024):
                            if chunk:
                                fh.write(chunk)
                    size = os.path.getsize(out_zip)
                    print(f'run {runid} saved zip size: {size}')
                    if size > 0:
                        try:
                            with zipfile.ZipFile(out_zip, 'r') as z:
                                z.extractall(out_dir)
                            print(f'run {runid} extracted to {out_dir}')
                        except zipfile.BadZipFile:
                            print(f'run {runid} bad zip file', file=sys.stderr)
                    return True
                else:
                    print(f'run {runid} failed to download archive, status {r2.status_code}')
            else:
                print(f'run {runid} no redirect, status {r.status_code} body snippet: {r.text[:300]}')
        except Exception as e:
            print(f'run {runid} error: {e}', file=sys.stderr)
    return False


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: download_runs_py.py <runid> [runid ...]', file=sys.stderr)
        sys.exit(1)
    os.makedirs('ci_logs', exist_ok=True)
    token = read_token()
    for rid in sys.argv[1:]:
        download_run(rid, token)
