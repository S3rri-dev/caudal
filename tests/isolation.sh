#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
cd "${0:A:h}/.."
[[ -d 'dist/Caudal Dev.app' ]] || ./scripts/build.sh --dev
scratch="$(mktemp -d "${TMPDIR:-/tmp}/caudal-isolation.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
CAUDAL_DATA="$scratch/public" dist/Caudal.app/Contents/MacOS/Caudal --check > "$scratch/public.json"
CAUDAL_DATA="$scratch/dev" 'dist/Caudal Dev.app/Contents/MacOS/Caudal' --check > "$scratch/dev.json"
python3 - "$scratch" <<'PY'
import json,plistlib,sqlite3,sys
from pathlib import Path
r=Path(sys.argv[1]);checks=0
for app,folder,bid,part in [('Caudal','Caudal','io.github.s3rri-dev.caudal','public'),('Caudal Dev','Caudal Dev','io.github.s3rri-dev.caudal.dev','dev')]:
 p=plistlib.loads(Path('dist',app+'.app','Contents/Info.plist').read_bytes());result=json.loads((r/(part+'.json')).read_text())
 assert p['CFBundleIdentifier']==bid and p['CaudalDataFolder']==folder;checks+=1
 assert result['ok'] and result['defaultDataFolder']==folder and all(v==0 for v in result['counts'].values());checks+=1
 assert result['totals']=={'liquid':0,'debt':0,'reserved':0};checks+=1
 c=sqlite3.connect(r/part/'caudal.sqlite');assert c.execute('PRAGMA application_id').fetchone()[0]==1128355121;checks+=1
 assert c.execute('PRAGMA integrity_check').fetchone()[0]=='ok';checks+=1;c.close()
# Mutating the isolated public DB cannot create a record in the Dev DB.
c=sqlite3.connect(r/'public/caudal.sqlite');c.execute("INSERT INTO accounts VALUES('isolation','Ficticia','bank',100)");c.commit();c.close()
c=sqlite3.connect(r/'dev/caudal.sqlite');assert c.execute('SELECT count(*) FROM accounts').fetchone()[0]==0;checks+=1;c.close()
print(f'OK · {checks} comprobaciones de identidad, arranque vacío e independencia public/Dev.')
PY
