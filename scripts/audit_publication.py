#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Detect private artifacts in source, Git history and release bundles."""
import argparse, json, plistlib, re, subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--bundle',type=Path)
parser.add_argument('--history',action='store_true')
a=parser.parse_args()
excluded={'build','dist','.git','__pycache__'}
patterns=[('personal path',rb'/(?:Users|home)/[A-Za-z0-9][A-Za-z0-9._-]+/'),
          ('GitHub token',rb'gh[pousr]_[A-Za-z0-9]{30,}'),
          ('fine-grained token',rb'github_pat_[A-Za-z0-9_]{40,}'),
          ('private key',rb'-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----'),
          ('legacy personal identity',rb'es\.luisserrano\.'),
          ('legacy environment',rb'FINANZAS_DATA\s*=')]
errors=[];count=0
private_suffixes={'.sqlite','.sqlite3','.db','.p12','.p8','.key','.log','.dmg','.zip'}
def check(name,data):
 for label,pattern in patterns:
  if re.search(pattern,data):errors.append(name+': '+label)
def inspect(p,label):
 global count
 if p.is_symlink():errors.append(label+': symlink not allowed');return
 if not p.is_file():return
 if p.suffix.lower() in private_suffixes or '.sqlite-' in p.name or p.name.startswith('.env'):
  errors.append(label+': private/generated artifact')
 check(label,p.read_bytes());count+=1
for p in root.rglob('*'):
 if not any(x in excluded for x in p.relative_to(root).parts):inspect(p,str(p.relative_to(root)))
if a.bundle:
 bundle=a.bundle.resolve();info=plistlib.loads((bundle/'Contents/Info.plist').read_bytes())
 ids={'io.github.s3rri-dev.caudal':('Caudal','Caudal'),'io.github.s3rri-dev.caudal.dev':('Caudal Dev','Caudal Dev')}
 expected=ids.get(info.get('CFBundleIdentifier'))
 if not expected or (info.get('CFBundleDisplayName'),info.get('CaudalDataFolder'))!=expected:errors.append('Unexpected bundle identity/storage')
 for p in bundle.rglob('*'):inspect(p,'bundle/'+str(p.relative_to(bundle)))
 binary=bundle/'Contents/MacOS/Caudal'
 arch=subprocess.check_output(['lipo','-archs',str(binary)],text=True).strip()
 if arch!='arm64':errors.append('Unexpected architecture: '+arch)
 for name in ['LICENSE.txt','TRADEMARKS.md','THIRD_PARTY_NOTICES.md']:
  if not (bundle/'Contents/Resources'/name).is_file():errors.append('Missing bundle notice: '+name)
 if info.get('LSMinimumSystemVersion')!='13.0':errors.append('Unexpected deployment target')
if a.history:
 commits=subprocess.check_output(['git','rev-list','--all'],cwd=root,text=True).splitlines()
 for sha in commits:
  paths=subprocess.check_output(['git','ls-tree','-r','--name-only',sha],cwd=root,text=True).splitlines()
  for name in paths:
   if Path(name).suffix in private_suffixes or name.startswith(('build/','dist/')):errors.append(sha[:8]+'/'+name+': private artifact in history')
   check(sha[:8]+'/'+name,subprocess.check_output(['git','show',sha+':'+name],cwd=root))
  check('commit '+sha[:8],subprocess.check_output(['git','show','-s','--format=fuller',sha],cwd=root))
 if not commits:errors.append('No history to inspect')
if errors:
 print('\n'.join('ERROR: '+e for e in errors));raise SystemExit(1)
print(f'OK · {count} source/bundle files checked; no matching private artifacts, paths or credentials detected.')
print('Pattern checks complement manual review; they are not a complete security audit.')
