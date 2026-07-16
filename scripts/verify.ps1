$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root

yanxu 包 锁 .
if ($LASTEXITCODE -ne 0) { throw '依赖锁定失败' }

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

yanxu tools/言域.yx -- 内容检查 examples/青石镇/内容
if ($LASTEXITCODE -ne 0) { throw '青石镇内容检查失败' }

New-Item -ItemType Directory -Force -Path dist | Out-Null
yanxu --max-steps 20000000 tools/言域.yx -- 构建 --输出 dist/青石镇世界.yj --覆盖 examples/青石镇/内容
if ($LASTEXITCODE -ne 0) { throw '青石镇内容制品构建失败' }

yanxu 编 . -o build --release
if ($LASTEXITCODE -ne 0) { throw '构建失败' }

& "$PSScriptRoot/check-history.ps1"
