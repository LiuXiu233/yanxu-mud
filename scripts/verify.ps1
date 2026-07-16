$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root

yanxu 包 锁 .
if ($LASTEXITCODE -ne 0) { throw '依赖锁定失败' }

$sources = Get-ChildItem -Path src,tools,tests,examples,benchmarks -Filter '*.yx' -File -Recurse -ErrorAction SilentlyContinue
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

yanxu 编 . -o build --release
if ($LASTEXITCODE -ne 0) { throw '构建失败' }

& "$PSScriptRoot/check-history.ps1"
