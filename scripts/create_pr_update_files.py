#!/usr/bin/env python3
"""
Create a branch and update files via GitHub API using token from .env, then open a PR.
Usage: create_pr_update_files.py --branch <branch-name> --title <pr-title> --body <pr-body> path1 path2 ...
"""
import os
import sys
import base64
import json
import requests
from pathlib import Path

REPO = 'Enio-Telles/sistema_ro'
API = f'https://api.github.com/repos/{REPO}'


def read_token():
    if not os.path.exists('.env'):
        return None
    with open('.env','r',encoding='utf-8') as f:
        for line in f:
            line=line.strip()
            if not line or line.startswith('#'): continue
            if '=' in line:
                k,v = line.split('=',1)
                if k.strip()=='GITHUB_TOKEN':
                    return v.strip()
    return None


def gh(method, path, token, **kwargs):
    url = API + path
    headers = {'Authorization': f'token {token}','Accept':'application/vnd.github+json','User-Agent':'sistema_ro-agent'}
    resp = requests.request(method, url, headers=headers, **kwargs)
    try:
        return resp.status_code, resp.json()
    except Exception:
        return resp.status_code, resp.text


def get_main_sha(token):
    st, data = gh('GET','/git/ref/heads/main',token)
    if st==200:
        return data['object']['sha']
    print('Failed to get main sha',st,data)
    return None


def create_branch(token, branch, sha):
    # create ref refs/heads/branch
    payload = {'ref': f'refs/heads/{branch}', 'sha': sha}
    st,data = gh('POST','/git/refs',token,json=payload)
    if st in (200,201):
        return True, data
    # if exists, return true
    if st==422 and isinstance(data,dict) and 'message' in data and 'Reference already exists' in data.get('message',''):
        return True, data
    return False, data


def get_file_sha(token, path):
    st,data = gh('GET', f'/contents/{path}?ref=main', token)
    if st==200:
        return data['sha']
    print(f'Failed to get file {path} sha from main: {st} {data}')
    return None


def update_file_on_branch(token, path, branch, message):
    p = Path(path)
    if not p.exists():
        print(f'Local file {path} not found, skipping')
        return False
    content = p.read_bytes()
    b64 = base64.b64encode(content).decode('ascii')
    sha = get_file_sha(token,path)
    payload = {'message': message, 'content': b64, 'branch': branch}
    if sha:
        payload['sha'] = sha
    st,data = gh('PUT', f'/contents/{path}', token, json=payload)
    return st,data


def create_pr(token, branch, title, body):
    payload = {'title': title, 'head': branch, 'base': 'main', 'body': body}
    st,data = gh('POST','/pulls',token,json=payload)
    return st,data


if __name__ == '__main__':
    if len(sys.argv) < 5:
        print('Usage: create_pr_update_files.py <branch> <pr-title> <pr-body> path1 [path2 ...]')
        sys.exit(2)
    branch = sys.argv[1]
    title = sys.argv[2]
    body = sys.argv[3]
    paths = sys.argv[4:]
    token = read_token()
    if not token:
        print('GITHUB_TOKEN not found in .env')
        sys.exit(1)
    main_sha = get_main_sha(token)
    if not main_sha:
        sys.exit(1)
    ok, info = create_branch(token, branch, main_sha)
    if not ok:
        print('Failed to create branch', info)
        sys.exit(1)
    print('Branch ready or exists')
    for p in paths:
        msg = f'Automated: update {p} for CI fixes'
        st,data = update_file_on_branch(token,p,branch,msg)
        print('Update file',p,'status',st)
        if st not in (200,201):
            print(data)
    st,data = create_pr(token, branch, title, body)
    print('Create PR status',st)
    print(data)

