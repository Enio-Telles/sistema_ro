#!/usr/bin/env python3
import os
import re
from pathlib import Path

root = Path('ci_logs')
if not root.exists():
    print('ci_logs folder not found. Run download_and_extract_logs.py first.')
    raise SystemExit(1)

patterns = [re.compile(r"Traceback \(most recent call last\):"),
            re.compile(r"ModuleNotFoundError:"),
            re.compile(r"ImportError:"),
            re.compile(r"FAILED \("),
            re.compile(r"FAILED tests"),
            re.compile(r"ERROR: ")] 

matches = []
for p in root.rglob('*'):
    if p.is_file():
        try:
            text = p.read_text(errors='ignore')
        except Exception:
            continue
        for pat in patterns:
            for m in pat.finditer(text):
                start = max(0, m.start()-200)
                end = min(len(text), m.end()+800)
                snippet = text[start:end]
                matches.append((str(p), pat.pattern, snippet))
                break

if not matches:
    print('No immediate tracebacks or failure markers found in extracted logs.')
else:
    for i,(path, pat, snip) in enumerate(matches,1):
        print(f"--- Match {i}: file={path} pattern={pat} ---")
        print(snip)
        print('\n')

print('Done scanning logs.')
