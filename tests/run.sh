#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
cd "${0:A:h}/.."
mkdir -p build/module-cache
xcrun swiftc -swift-version 5 -Onone -module-cache-path build/module-cache -I Sources/CSQLite Sources/Store.swift tests/main.swift -o build/tests
./build/tests
