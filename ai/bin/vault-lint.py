#!/usr/bin/env python3
"""Vault health check. Usage: vault-lint.py <vault-path> [--knowledge-dirs a,b,c] [--stale-days N]
Reports: broken wikilinks, orphan knowledge notes, missing frontmatter,
stale `synced:` mirrors, oversized hot.md. Read-only; exit 1 if issues found."""
import os, re, sys, argparse, datetime, collections

ap = argparse.ArgumentParser()
ap.add_argument('vault')
ap.add_argument('--knowledge-dirs', default='notes')
ap.add_argument('--stale-days', type=int, default=14)
a = ap.parse_args()
V = os.path.abspath(a.vault)
kdirs = [d.strip().rstrip('/') for d in a.knowledge_dirs.split(',') if d.strip()]
SKIP = ('.git', '.obsidian')
PLACEHOLDER = re.compile(r'[<>]|xxxx', re.I)

names, docs = set(), {}
for root, dirs, fs in os.walk(V):
    dirs[:] = [d for d in dirs if d not in SKIP]
    for f in fs:
        p = os.path.join(root, f)
        names.add(os.path.splitext(f)[0].lower())
        names.add(f.lower())  # embeds with extension: [[x.base]], [[img.png]]
        if f.endswith('.md'):
            docs[p] = open(p, encoding='utf-8', errors='ignore').read()

def rel(p): return os.path.relpath(p, V)
issues = collections.defaultdict(list)
inbound = collections.Counter()
today = datetime.date.today()

for p, txt in docs.items():
    r = rel(p)
    links = re.findall(r'\[\[([^\]|#]+)(?:[#|][^\]]*)?\]\]', txt)
    seen = set()
    for m in links:
        t = m.strip().rstrip('\\').strip(); base = t.split('/')[-1].lower()
        if base in names: inbound[base] += 1
        elif not (PLACEHOLDER.search(t) or '_templates/' in r or (r, t) in seen):
            seen.add((r, t))
            issues['broken links'].append(f'{r} -> [[{t}]]')
    fm = re.match(r'^---\n(.*?)\n---', txt, re.S)
    if any(r.startswith(k + os.sep) or r.startswith(k + '/') for k in kdirs):
        if not fm and not r.endswith(('README.md', 'INDEX.md')):
            issues['missing frontmatter'].append(r)
    m = re.search(r'^synced:\s*(\d{4}-\d{2}-\d{2})', txt, re.M)
    if m:
        age = (today - datetime.date.fromisoformat(m.group(1)[:10])).days
        if age > a.stale_days:
            issues[f'stale synced (>{a.stale_days}d)'].append(f'{r} ({age}d)')

for p, txt in docs.items():
    r = rel(p); base = os.path.basename(p)[:-3].lower()
    if not any(r.startswith(k + '/') or r.startswith(k + os.sep) for k in kdirs): continue
    if base.endswith(('readme', 'index')): continue
    has_out = bool(re.search(r'\[\[[^\]]+\]\]', txt))
    if inbound[base] == 0 and not has_out:
        issues['orphan knowledge notes'].append(r)

hot = os.path.join(V, 'hot.md')
if os.path.exists(hot):
    words = len(open(hot, encoding='utf-8', errors='ignore').read().split())
    if words > 600: issues['hot.md oversized'].append(f'{words} words (target ~500)')
else:
    issues['hot.md'].append('missing')

total = sum(len(v) for v in issues.values())
print(f'# vault-lint: {os.path.basename(V)} — {total} issue(s)\n')
for k, v in sorted(issues.items()):
    print(f'## {k} ({len(v)})')
    for line in sorted(v): print(f'- {line}')
    print()
sys.exit(1 if total else 0)
