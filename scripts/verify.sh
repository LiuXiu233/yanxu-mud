#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

yanxu 包 锁 .

while IFS= read -r -d '' source; do
  yanxu 格 --写 "$source"
done < <(find src tools tests examples benchmarks -type f -name '*.yx' -print0 2>/dev/null || true)

yanxu 查 src/言域.yx
yanxu 查 tools/言域.yx
yanxu 试 tests --json
yanxu 编 . -o build --release
"$root/scripts/check-history.sh"
