#!/usr/bin/env python3
"""Vault health check. Usage: vault-lint.py <vault-path> [--knowledge-dirs a,b,c] [--stale-days N]
       [--todo-dirs a,b] [--idea-dirs a,b] [--todo-stale-days N]
Reports: broken wikilinks, orphan knowledge notes, missing frontmatter,
stale `synced:` mirrors, oversized hot.md, open todos untouched for N days,
todo/idea notes whose status doesn't match their folder. Read-only; exit 1 if issues found."""
import os, re, sys, argparse, datetime, collections, subprocess

ap = argparse.ArgumentParser()
ap.add_argument('vault')
ap.add_argument('--knowledge-dirs', default='notes')
ap.add_argument('--stale-days', type=int, default=14)
ap.add_argument('--todo-dirs', default='todos')
ap.add_argument('--idea-dirs', default='ideas')
ap.add_argument('--todo-stale-days', type=int, default=28)
a = ap.parse_args()
V = os.path.abspath(a.vault)
def dirlist(s): return [d.strip().rstrip('/') for d in s.split(',') if d.strip()]
kdirs, tdirs, idirs = dirlist(a.knowledge_dirs), dirlist(a.todo_dirs), dirlist(a.idea_dirs)
OPEN, IDEA = ('todo', 'in-progress'), ('idea', 'graduated')
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
            try:
                docs[p] = open(p, encoding='utf-8', errors='ignore').read()
            except OSError as e:  # sandboxed agents are denied some private notes
                print(f'skipped {os.path.relpath(p, V)}: {e.strerror}', file=sys.stderr)

def rel(p): return os.path.relpath(p, V)
issues = collections.defaultdict(list)
inbound = collections.Counter()
today = datetime.date.today()

for p, txt in docs.items():
    r = rel(p)
    # Obsidian doesn't resolve links inside code, and bash tests look like [[ -f x ]].
    scan = re.sub(r'```.*?```', '', txt, flags=re.S)
    scan = re.sub(r'`.*?`', '', scan)
    links = re.findall(r'\[\[(?![ \t])([^\]|#]+)(?:[#|][^\]]*)?\]\]', scan)
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

def under(r, ds): return next((d for d in ds if r.startswith(d + '/') or r.startswith(d + os.sep)), None)

# Last commit per file, not mtime: a fresh clone gives every file today's mtime.
touched = {}
try:
    if not tdirs: raise OSError
    git =['git', '-C', V, '-c', 'core.quotePath=false']
    out = subprocess.run(git + ['log', '--format=%x00%cs', '--name-only', '--', *tdirs],
                         capture_output=True, text=True, check=True).stdout
    day = None
    for line in out.splitlines():
        if line.startswith('\0'): day = line[1:]
        elif line: touched.setdefault(line, day)
    out = subprocess.run(git + ['status', '--porcelain', '--', *tdirs],
                         capture_output=True, text=True, check=True).stdout
    for line in out.splitlines(): touched[line[3:].split(' -> ')[-1]] = today.isoformat()
except (OSError, subprocess.CalledProcessError):
    touched = None  # not a git repo

for p, txt in docs.items():
    r = rel(p); base = os.path.basename(p)[:-3].lower()
    td, idd = under(r, tdirs), under(r, idirs)
    if not (td or idd): continue
    # Folder indexes (todos/TODO.md, ideas/ideas.md) carry a status but aren't items.
    if base in ('readme', 'index', 'todo') or base == os.path.basename(os.path.dirname(p)).lower(): continue
    fm = re.match(r'^---\n(.*?)\n---', txt, re.S)
    m = fm and re.search(r'^status:\s*["\']?([\w-]+)', fm.group(1), re.M)
    st = m.group(1).lower() if m else None
    if td and st in OPEN:
        day = touched.get(r) if touched is not None else \
            datetime.date.fromtimestamp(os.path.getmtime(p)).isoformat()
        age = (today - datetime.date.fromisoformat(day)).days if day else 0
        if age > a.todo_stale_days:
            issues[f'stale todos (>{a.todo_stale_days}d untouched)'].append(f'{r} ({st}, {age}d)')
    elif idd and st in IDEA:
        pass
    elif not st:
        issues['status vs folder'].append(f'{r}: no status')
    elif td and st == 'done':
        issues['status vs folder'].append(f'{r}: done, archive it')
    elif td and st in IDEA:
        issues['status vs folder'].append(f'{r}: {st}, move to {(idirs or ["ideas"])[0]}/')
    elif idd and st in OPEN:
        issues['status vs folder'].append(f'{r}: {st}, move to {(tdirs or ["todos"])[0]}/')
    else:
        issues['status vs folder'].append(f'{r}: unknown status {st}')

hot =os.path.join(V, 'hot.md')
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
