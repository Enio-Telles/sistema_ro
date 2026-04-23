#!/usr/bin/env python3
import os
import sys
import requests
import zipfile
from pathlib import Path

REPO = "Enio-Telles/sistema_ro"
BASE = "https://api.github.com/repos/" + REPO

def read_token(env_path='.env'):
    if not os.path.exists(env_path):
        return None
    with open(env_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if '=' in line:
                k, v = line.split('=', 1)
                if k.strip() == 'GITHUB_TOKEN':
                    return v.strip()
    return None


def download_run_logs(token, run_id, out_dir):
    url = f"{BASE}/actions/runs/{run_id}/logs"
    headers = {'Authorization': f'token {token}', 'Accept': 'application/zip', 'User-Agent': 'sistema_ro-agent'}
    resp = requests.get(url, headers=headers, stream=True)
    if resp.status_code != 200:
        print(f"Failed to download run {run_id} logs: {resp.status_code} {resp.text[:400]}")
        return False
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    zip_path = out_dir / f"run-{run_id}.zip"
    with open(zip_path, 'wb') as fh:
        for chunk in resp.iter_content(chunk_size=8192):
            if chunk:
                fh.write(chunk)
    try:
        with zipfile.ZipFile(zip_path, 'r') as z:
            extract_to = out_dir / f"run-{run_id}"
            extract_to.mkdir(parents=True, exist_ok=True)
            z.extractall(path=str(extract_to))
        print(f"Downloaded and extracted {zip_path} -> {extract_to}")
        return True
    except zipfile.BadZipFile:
        print(f"Downloaded file at {zip_path} is not a valid zip")
        return False


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: download_and_extract_logs.py <run_id> [<run_id> ...]")
        sys.exit(2)
    token = read_token()
    if not token:
        print("GITHUB_TOKEN not found in .env")
        sys.exit(1)
    runs = sys.argv[1:]
    base_out = Path('ci_logs')
    base_out.mkdir(exist_ok=True)
    for run in runs:
        success = download_run_logs(token, run, base_out)
        if not success:
            print(f"Failed for run {run}")

    print("Done")
