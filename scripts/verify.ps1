$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root

yanxu 包 锁 .
if ($LASTEXITCODE -ne 0) { throw '依赖锁定失败' }

if (-not $env:YANYU_SQLITE3) {
    $sqlite = Get-Command sqlite3 -ErrorAction SilentlyContinue
    if (-not $sqlite) { throw '缺少 SQLite 3.38+ CLI；请安装 sqlite3 或设置 YANYU_SQLITE3' }
    $env:YANYU_SQLITE3 = $sqlite.Source
}
& $env:YANYU_SQLITE3 --version
if ($LASTEXITCODE -ne 0) { throw 'SQLite CLI 不可执行' }

$sources = Get-ChildItem -Path src,tools,tests,api-tests,examples,benchmarks -Filter '*.yx' -File -Recurse -ErrorAction SilentlyContinue
foreach ($source in $sources) {
    yanxu 格 --写 $source.FullName
    if ($LASTEXITCODE -ne 0) { throw "格式化失败：$($source.FullName)" }
}

$entrypoints = @('src/言域.yx', 'tools/言域.yx')
foreach ($entrypoint in $entrypoints) {
    yanxu 查 $entrypoint
    if ($LASTEXITCODE -ne 0) { throw "静态检查失败：$entrypoint" }
}

yanxu 试 tests --json
if ($LASTEXITCODE -ne 0) { throw '规格测试失败' }

yanxu 兼容 tests --json
if ($LASTEXITCODE -ne 0) { throw '双执行器兼容测试失败' }

Push-Location -LiteralPath "$root/api-tests"
try {
    yanxu 包 锁 .
    if ($LASTEXITCODE -ne 0) { throw '公共 API 测试依赖锁定失败' }
    yanxu 试 tests --json
    if ($LASTEXITCODE -ne 0) { throw '公共 API 测试失败' }
    yanxu 兼容 tests --json
    if ($LASTEXITCODE -ne 0) { throw '公共 API 双执行器兼容测试失败' }
}
finally {
    Pop-Location
}

yanxu tools/言域.yx -- 内容检查 --行为 言域:技能行为/伤害 --行为 言域:计划行为/刷新 --行为 言域:AI行为/敌对近战 examples/青石镇/内容
if ($LASTEXITCODE -ne 0) { throw '青石镇内容检查失败' }

$verifyDirectory = Join-Path $root '.yanxu/verify'
New-Item -ItemType Directory -Force -Path $verifyDirectory | Out-Null
yanxu --max-steps 20000000 tools/言域.yx -- 构建 --行为 言域:技能行为/伤害 --行为 言域:计划行为/刷新 --行为 言域:AI行为/敌对近战 --输出 "$verifyDirectory/青石镇世界.yj" --覆盖 examples/青石镇/内容
if ($LASTEXITCODE -ne 0) { throw '青石镇内容制品构建失败' }

yanxu 编 . -o build --release
if ($LASTEXITCODE -ne 0) { throw '构建失败' }

& "$PSScriptRoot/check-history.ps1"
