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

$gameRoot = Join-Path $root 'examples/青石镇'
Push-Location -LiteralPath $gameRoot
try {
    yanxu 包 锁 .
    if ($LASTEXITCODE -ne 0) { throw '青石镇依赖锁定失败' }
    yanxu tools/生成击杀结算夹具.yx
    if ($LASTEXITCODE -ne 0) { throw '青石镇击杀结算夹具生成失败' }
    git diff --exit-code -- tests/fixtures/击杀结算.json
    if ($LASTEXITCODE -ne 0) { throw '青石镇击杀结算夹具未重新生成' }
    yanxu 试 tests --json
    if ($LASTEXITCODE -ne 0) { throw '青石镇规格测试失败' }
    yanxu 兼容 tests --json
    if ($LASTEXITCODE -ne 0) { throw '青石镇双执行器兼容测试失败' }
}
finally {
    Pop-Location
}

$consoleState = ".yanxu/verify-console-$([Guid]::NewGuid().ToString('N')).json"
yanxu 包 运行 . -- 控制台 --命令 '退出' --存档 $consoleState --json examples/青石镇
if ($LASTEXITCODE -ne 0) { throw '默认预算本地控制台运行失败' }

& "$PSScriptRoot/network-e2e.ps1" -Yanxu (Get-Command yanxu).Source
if ($LASTEXITCODE -ne 0) { throw '默认预算实际网络端到端失败' }

yanxu tools/言域.yx -- 内容检查 --行为 言域:技能行为/伤害 --行为 言域:计划行为/刷新 --行为 言域:AI行为/敌对近战 examples/青石镇/内容
if ($LASTEXITCODE -ne 0) { throw '青石镇内容检查失败' }

$verifyDirectory = Join-Path $root '.yanxu/verify'
New-Item -ItemType Directory -Force -Path $verifyDirectory | Out-Null
yanxu --max-steps 20000000 tools/言域.yx -- 构建 --行为 言域:技能行为/伤害 --行为 言域:计划行为/刷新 --行为 言域:AI行为/敌对近战 --输出 "$verifyDirectory/青石镇世界.yj" --覆盖 examples/青石镇/内容
if ($LASTEXITCODE -ne 0) { throw '青石镇内容制品构建失败' }

$builtWorld = Join-Path $verifyDirectory '青石镇世界.yj'
$committedWorld = Join-Path $gameRoot '世界.yj'
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $builtWorld).Hash -ne (Get-FileHash -Algorithm SHA256 -LiteralPath $committedWorld).Hash) {
    throw '青石镇世界制品未按当前内容重新生成'
}

$runtimeDirectory = Join-Path $verifyDirectory ("runtime-$([Guid]::NewGuid().ToString('N'))")
yanxu --max-steps 20000000 tools/构建青石镇运行时.yx -- $builtWorld $runtimeDirectory
if ($LASTEXITCODE -ne 0) { throw '青石镇运行时分片构建失败' }

function Get-TreeManifest([string]$directory) {
    $base = [System.IO.Path]::GetFullPath($directory)
    @(Get-ChildItem -LiteralPath $base -Recurse -File | ForEach-Object {
        $relative = [System.IO.Path]::GetRelativePath($base, $_.FullName).Replace('\', '/')
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash.ToLowerInvariant()
        "$relative`t$hash"
    } | Sort-Object)
}

$committedRuntime = Join-Path $gameRoot '运行时世界'
$runtimeDifference = Compare-Object -ReferenceObject (Get-TreeManifest $committedRuntime) -DifferenceObject (Get-TreeManifest $runtimeDirectory)
if ($runtimeDifference) {
    $runtimeDifference | Format-Table | Out-String | Write-Host
    throw '青石镇运行时分片未按当前世界制品重新生成'
}

yanxu 编 . -o build --release
if ($LASTEXITCODE -ne 0) { throw '构建失败' }

& "$PSScriptRoot/check-history.ps1"
