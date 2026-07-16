#!/usr/bin/env bash
set -euo pipefail

if git log --format='%H%n%an%n%ae%n%s%n%b' | grep -qi 'codex'; then
  echo '提交作者、邮箱、标题或正文含有禁用的自动化署名。' >&2
  exit 1
fi

echo 'Git 提交元数据检查通过。'
