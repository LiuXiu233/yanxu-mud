#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

yanxu 包 锁 .

if [[ -z "${YANYU_SQLITE3:-}" ]]; then
  YANYU_SQLITE3="$(command -v sqlite3 || true)"
  export YANYU_SQLITE3
fi
if [[ -z "$YANYU_SQLITE3" ]]; then
  echo '缺少 SQLite 3.38+ CLI；请安装 sqlite3 或设置 YANYU_SQLITE3' >&2
  exit 1
fi
"$YANYU_SQLITE3" --version

while IFS= read -r -d '' source; do
  yanxu 格 --写 "$source"
done < <(find src tools tests api-tests examples benchmarks -type f -name '*.yx' -print0 2>/dev/null || true)

yanxu 查 src/言域.yx
yanxu 查 tools/言域.yx
yanxu 试 tests --json
yanxu 兼容 tests --json
(
  cd api-tests
  yanxu 包 锁 .
  yanxu 试 tests --json
  yanxu 兼容 tests --json
)
yanxu tools/言域.yx -- 内容检查 --行为 言域:技能行为/伤害 examples/青石镇/内容
mkdir -p .yanxu/verify
yanxu --max-steps 20000000 tools/言域.yx -- 构建 --行为 言域:技能行为/伤害 --输出 .yanxu/verify/青石镇世界.yj --覆盖 examples/青石镇/内容
yanxu 编 . -o build --release
"$root/scripts/check-history.sh"
