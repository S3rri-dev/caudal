#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
cd "${0:A:h}/.."
variant="${1:-release}"
[[ "$variant" == release || "$variant" == --dev ]] || { print 'Uso: scripts/build.sh [--dev]'; exit 2; }
app_name=Caudal
bundle_id=io.github.s3rri-dev.caudal
data_folder=Caudal
if [[ "$variant" == --dev ]]; then
  app_name='Caudal Dev'; bundle_id=io.github.s3rri-dev.caudal.dev; data_folder='Caudal Dev'
fi
mkdir -p build/module-cache
app_dir="dist/$app_name.app"
# Solo se reemplaza el producto de compilación, nunca una app instalada ni datos.
[[ ! -L "$app_dir" ]] || { print 'El destino de compilación no puede ser un enlace'; exit 2; }
if [[ -d "$app_dir" ]]; then mv "$app_dir" "build/previous-$app_name-$(date +%Y%m%d%H%M%S)-$$.app"; fi
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
xcrun swiftc -swift-version 5 -target arm64-apple-macosx13.0 -O -debug-prefix-map "$PWD"=. -file-prefix-map "$PWD"=. -module-cache-path build/module-cache -I Sources/CSQLite -framework AppKit -framework WebKit Sources/*.swift -o "$app_dir/Contents/MacOS/Caudal"
cp -R Resources/. "$app_dir/Contents/Resources/"
cp LICENSE "$app_dir/Contents/Resources/LICENSE.txt"
cp TRADEMARKS.md THIRD_PARTY_NOTICES.md "$app_dir/Contents/Resources/"
APP_OUTPUT="$app_dir" APP_LABEL="$app_name" APP_IDENTIFIER="$bundle_id" APP_DATA_FOLDER="$data_folder" python3 - <<'PY'
import json,plistlib,os,subprocess
from pathlib import Path
v=json.loads(Path('version.json').read_text())
d=dict(CFBundleExecutable='Caudal',CFBundleIdentifier=os.environ['APP_IDENTIFIER'],
       CFBundleName=os.environ['APP_LABEL'],CFBundleDisplayName=os.environ['APP_LABEL'],
       CFBundleDevelopmentRegion='es',CFBundleLocalizations=['es'],CFBundleVersion=str(v['build']),
       CFBundleShortVersionString=v['version'],CFBundlePackageType='APPL',CFBundleIconFile='AppIcon',
       LSMinimumSystemVersion='13.0',NSHighResolutionCapable=True,NSPrincipalClass='NSApplication',
       CaudalDataFolder=os.environ['APP_DATA_FOLDER'],
       CaudalSourceCommit=subprocess.run(['git','rev-parse','HEAD'],text=True,capture_output=True).stdout.strip() or 'uncommitted',
       NSHumanReadableCopyright='Copyright © 2026 S3rri-dev y colaboradores. Código GPL-3.0-or-later, sin garantía; identidad reservada.')
Path(os.environ['APP_OUTPUT'],'Contents/Info.plist').write_bytes(plistlib.dumps(d,sort_keys=False))
PY
codesign --force --deep --sign - "$app_dir"
codesign --verify --deep --strict "$app_dir"
print "Compilada: $app_dir · ARM64 · firma ad hoc"
