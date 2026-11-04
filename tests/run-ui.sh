#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
cd "${0:A:h}/.."
test_root="$PWD/build/ui-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$test_root"
CAUDAL_DATA="$test_root" 'dist/Caudal.app/Contents/MacOS/Caudal' --ui-test > "$test_root/native.log" 2>&1 &
app_pid=$!
trap 'kill "$app_pid" 2>/dev/null || true; wait "$app_pid" 2>/dev/null || true' EXIT INT TERM
printf '%s\n' "$test_root" > build/latest-ui-path.txt
for attempt in {1..60}; do
  if [[ -f "$test_root/ui-result.json" ]]; then
    python3 - "$test_root/ui-result.json" <<'PY'
import json,sys
with open(sys.argv[1]) as f: result=json.load(f)
print(json.dumps({'ok':result['ok'],'checks':result.get('checks',len(result.get('results',[]))),'error':result.get('error'),'captures':len(result.get('captures',[])),'report':sys.argv[1],'contrast':result.get('contrastResults',[])},ensure_ascii=False,indent=2))
sys.exit(0 if result['ok'] else 1)
PY
    exit $?
  fi
  if ! kill -0 "$app_pid" 2>/dev/null; then cat "$test_root/native.log"; exit 1; fi
  sleep 1
done
printf '%s\n' "No se recibió resultado de WebKit. Revisa $test_root/native.log"
exit 1
