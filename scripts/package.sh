#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
cd "${0:A:h}/.."
[[ -z "$(git status --porcelain)" ]] || { print 'La copia pública debe estar limpia y confirmada antes de empaquetar.'; exit 2; }
app='dist/Caudal.app'
[[ -d "$app" ]] || { print 'Compila primero scripts/build.sh'; exit 2; }
commit="$(git rev-parse HEAD)"
[[ "$(plutil -extract CaudalSourceCommit raw "$app/Contents/Info.plist")" == "$commit" ]] || { print 'Compila desde el commit actual antes de empaquetar.'; exit 2; }
python3 scripts/audit_publication.py --history --bundle "$app"
codesign --verify --deep --strict "$app"
version="$(plutil -extract CFBundleShortVersionString raw "$app/Contents/Info.plist")"
for artifact in "dist/Caudal-$version-arm64.dmg" "dist/Caudal-$version-arm64-app.zip" "dist/Caudal-$version-src.zip"; do
 [[ ! -e "$artifact" ]] || { print "Ya existe $artifact; conserva el paquete antes de repetir."; exit 2; }
done
stage="$(mktemp -d "$PWD/build/package.XXXXXX")"
ditto "$app" "$stage/Caudal.app"
cp LICENSE TRADEMARKS.md THIRD_PARTY_NOTICES.md "$stage/"
cp docs/DISTRIBUTION.txt "$stage/LEEME.txt"
ln -s /Applications "$stage/Aplicaciones"
hdiutil create -volname Caudal -srcfolder "$stage" -format UDZO -o "dist/Caudal-$version-arm64.dmg"
hdiutil verify "dist/Caudal-$version-arm64.dmg"
ditto -c -k --sequesterRsrc --keepParent "$app" "dist/Caudal-$version-arm64-app.zip"
git archive --format=zip --prefix="Caudal-$version/" --output="dist/Caudal-$version-src.zip" HEAD
CAUDAL_VERSION="$version" python3 - <<'PY'
import os,json,hashlib,subprocess,plistlib
from pathlib import Path
v=os.environ['CAUDAL_VERSION'];dist=Path('dist')
names=[f'Caudal-{v}-arm64.dmg',f'Caudal-{v}-arm64-app.zip',f'Caudal-{v}-src.zip']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
ui_path=Path('build/latest-ui-path.txt')
ui=json.loads((Path(ui_path.read_text().strip())/'ui-result.json').read_text()) if ui_path.exists() else {}
assert ui.get('ok'), 'Ejecuta tests/run-ui.sh antes de empaquetar'
manifest=dict(version=v,source_commit=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),
 source_tree=subprocess.check_output(['git','rev-parse','HEAD^{tree}'],text=True).strip(),
 architecture='arm64',deployment_target='13.0',signing='ad-hoc',developer_id=False,notarized=False,
 origin='GitHub Actions' if os.getenv('GITHUB_ACTIONS')=='true' else 'local verified build',
 build_os=subprocess.check_output(['sw_vers','-productVersion'],text=True).strip(),
 compiler=subprocess.check_output(['xcrun','swiftc','--version'],text=True).strip(),
 ui_checks=ui['checks'],ui_result='passed',
 artifacts={n:dict(sha256=sha(dist/n),bytes=(dist/n).stat().st_size) for n in names})
n=f'Caudal-{v}-manifest.json';(dist/n).write_text(json.dumps(manifest,indent=2)+'\n');names.append(n)
(dist/'SHA256SUMS.txt').write_text(''.join(sha(dist/n)+'  '+n+'\n' for n in names))
print('Paquetes listos; manifiesto ligado al commit',manifest['source_commit'])
PY
