$ErrorActionPreference = 'Stop'

$history = git log --format='%H%n%an%n%ae%n%s%n%b'
if ($LASTEXITCODE -ne 0) { throw '无法读取 Git 历史' }

if ($history -match '(?i)codex') {
    Write-Error '提交作者、邮箱、标题或正文含有禁用的自动化署名。'
    exit 1
}

Write-Host 'Git 提交元数据检查通过。'
