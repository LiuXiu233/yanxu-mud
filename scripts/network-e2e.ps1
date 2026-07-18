param(
    [string]$Yanxu = 'yanxu'
)

$ErrorActionPreference = 'Stop'

$root = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$gameRoot = [System.IO.Path]::GetFullPath((Join-Path $root 'examples/青石镇'))
$runId = [Guid]::NewGuid().ToString('N')
$relativeStateRoot = ".yanxu/network-e2e-$runId"
$stateRoot = [System.IO.Path]::GetFullPath((Join-Path $gameRoot $relativeStateRoot))
$processes = [System.Collections.Generic.List[System.Diagnostics.Process]]::new()
$results = [System.Collections.Generic.List[object]]::new()
$completed = $false

if (-not $stateRoot.StartsWith($gameRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw '网络 E2E 临时目录越出青石镇包根'
}

New-Item -ItemType Directory -Force -Path $stateRoot | Out-Null

function Get-FreeTcpPort {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    $listener.Start()
    try {
        return ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port
    }
    finally {
        $listener.Stop()
    }
}

function Start-QingstoneServer {
    param(
        [string]$Mode,
        [int]$Port,
        [string]$StateName,
        [string]$WebSocketUrl = 'ws://127.0.0.1:8081/ws'
    )

    $stdoutPath = Join-Path $stateRoot "$Mode.stdout.txt"
    $stderrPath = Join-Path $stateRoot "$Mode.stderr.txt"
    $start = [System.Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $Yanxu
    $start.WorkingDirectory = $gameRoot
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $start.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $start.Environment['YANYU_SESSION_SECRET'] = 'network-e2e-session-secret-0123456789abcdef'
    $start.Environment['YANYU_LOGIN_NAME'] = 'network-e2e'
    $start.Environment['YANYU_LOGIN_SECRET'] = 'network-e2e-login-secret'
    $start.Environment['YANYU_ADMIN_TOKEN'] = 'network-e2e-admin-token'

    $arguments = @(
        '包', '运行', '.', '--',
        '--模式', $Mode,
        '--地址', "127.0.0.1:$Port",
        '--次数', '1',
        '--存档', "$relativeStateRoot/$StateName.json",
        '--websocket地址', $WebSocketUrl
    )
    foreach ($argument in $arguments) {
        $start.ArgumentList.Add($argument)
    }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $start
    if (-not $process.Start()) {
        throw "无法启动青石镇 $Mode 服务"
    }
    $processes.Add($process)
    $process | Add-Member -NotePropertyName E2EStdoutPath -NotePropertyValue $stdoutPath
    $process | Add-Member -NotePropertyName E2EStderrPath -NotePropertyValue $stderrPath
    return $process
}

function Complete-QingstoneServer {
    param(
        [System.Diagnostics.Process]$Process,
        [string]$Mode
    )

    if (-not $Process.WaitForExit(20000)) {
        $Process.Kill($true)
        throw "青石镇 $Mode 服务未在有限请求后退出"
    }
    $stdout = $Process.StandardOutput.ReadToEnd()
    $stderr = $Process.StandardError.ReadToEnd()
    [System.IO.File]::WriteAllText($Process.E2EStdoutPath, $stdout, [System.Text.Encoding]::UTF8)
    [System.IO.File]::WriteAllText($Process.E2EStderrPath, $stderr, [System.Text.Encoding]::UTF8)
    if ($Process.ExitCode -ne 0) {
        throw "青石镇 $Mode 服务失败，退出码 $($Process.ExitCode)`n标准输出：$stdout`n标准错误：$stderr"
    }
    return [ordered]@{
        mode = $Mode
        exitCode = $Process.ExitCode
        stdout = $stdout.Trim()
        stderr = $stderr.Trim()
    }
}

function Connect-TcpWithRetry {
    param([int]$Port)

    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    while ([DateTime]::UtcNow -lt $deadline) {
        $client = [System.Net.Sockets.TcpClient]::new()
        try {
            $task = $client.ConnectAsync('127.0.0.1', $Port)
            if ($task.Wait(300) -and $client.Connected) {
                return $client
            }
        }
        catch {
        }
        $client.Dispose()
        Start-Sleep -Milliseconds 50
    }
    throw "无法连接 127.0.0.1:$Port"
}

function Read-TcpUntil {
    param(
        [System.Net.Sockets.NetworkStream]$Stream,
        [string]$Expected
    )

    $memory = [System.IO.MemoryStream]::new()
    $buffer = [byte[]]::new(8192)
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    try {
        while ([DateTime]::UtcNow -lt $deadline) {
            if ($Stream.DataAvailable) {
                $count = $Stream.Read($buffer, 0, $buffer.Length)
                if ($count -eq 0) { break }
                $memory.Write($buffer, 0, $count)
                $text = [System.Text.Encoding]::UTF8.GetString($memory.ToArray())
                if ($text.Contains($Expected, [System.StringComparison]::Ordinal)) {
                    return $text
                }
            }
            else {
                Start-Sleep -Milliseconds 20
            }
        }
        $actual = [System.Text.Encoding]::UTF8.GetString($memory.ToArray())
        throw "TCP 响应未包含 [$Expected]：$actual"
    }
    finally {
        $memory.Dispose()
    }
}

function Write-TcpLine {
    param(
        [System.Net.Sockets.NetworkStream]$Stream,
        [string]$Line
    )

    $bytes = [System.Text.Encoding]::UTF8.GetBytes("$Line`r`n")
    $Stream.Write($bytes, 0, $bytes.Length)
    $Stream.Flush()
}

function Connect-WebSocketWithRetry {
    param(
        [int]$Port,
        [string]$Origin
    )

    $uri = [Uri]"ws://127.0.0.1:$Port/ws"
    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    while ([DateTime]::UtcNow -lt $deadline) {
        $socket = [System.Net.WebSockets.ClientWebSocket]::new()
        $socket.Options.SetRequestHeader('Origin', $Origin)
        $socket.Options.AddSubProtocol('yanyu.v1')
        try {
            $cancellation = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds(2))
            try {
                $socket.ConnectAsync($uri, $cancellation.Token).GetAwaiter().GetResult() | Out-Null
            }
            finally {
                $cancellation.Dispose()
            }
            if ($socket.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
                return $socket
            }
        }
        catch {
        }
        $socket.Dispose()
        Start-Sleep -Milliseconds 50
    }
    throw "无法建立 WebSocket：$uri"
}

function Send-WebSocketText {
    param(
        [System.Net.WebSockets.ClientWebSocket]$Socket,
        [string]$Text
    )

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $segment = [System.ArraySegment[byte]]::new($bytes)
    $Socket.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult() | Out-Null
}

function Receive-WebSocketText {
    param([System.Net.WebSockets.ClientWebSocket]$Socket)

    $buffer = [byte[]]::new(8192)
    $memory = [System.IO.MemoryStream]::new()
    try {
        do {
            $segment = [System.ArraySegment[byte]]::new($buffer)
            $cancellation = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds(10))
            try {
                $received = $Socket.ReceiveAsync($segment, $cancellation.Token).GetAwaiter().GetResult()
            }
            finally {
                $cancellation.Dispose()
            }
            if ($received.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) {
                throw 'WebSocket 在返回文本响应前关闭'
            }
            $memory.Write($buffer, 0, $received.Count)
        } while (-not $received.EndOfMessage)
        return [System.Text.Encoding]::UTF8.GetString($memory.ToArray())
    }
    finally {
        $memory.Dispose()
    }
}

function Invoke-HttpWithRetry {
    param([int]$Port)

    $client = [System.Net.Http.HttpClient]::new()
    $client.Timeout = [TimeSpan]::FromSeconds(2)
    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    try {
        while ([DateTime]::UtcNow -lt $deadline) {
            try {
                return $client.GetAsync("http://127.0.0.1:$Port/healthz").GetAwaiter().GetResult()
            }
            catch {
                Start-Sleep -Milliseconds 50
            }
        }
        throw "无法访问 HTTP 127.0.0.1:$Port"
    }
    finally {
        $client.Dispose()
    }
}

try {
    $telnetPort = Get-FreeTcpPort
    $telnetProcess = Start-QingstoneServer -Mode 'Telnet' -Port $telnetPort -StateName 'telnet'
    $telnetClient = Connect-TcpWithRetry -Port $telnetPort
    try {
        $telnetStream = $telnetClient.GetStream()
        Read-TcpUntil -Stream $telnetStream -Expected '青石镇已连接' | Out-Null
        Write-TcpLine -Stream $telnetStream -Line '游客'
        Read-TcpUntil -Stream $telnetStream -Expected '会话已建立' | Out-Null
        Write-TcpLine -Stream $telnetStream -Line '观察'
        Read-TcpUntil -Stream $telnetStream -Expected '中央街' | Out-Null
        Write-TcpLine -Stream $telnetStream -Line '退出'
        Read-TcpUntil -Stream $telnetStream -Expected '会话已退出' | Out-Null
    }
    finally {
        $telnetClient.Dispose()
    }
    $results.Add((Complete-QingstoneServer -Process $telnetProcess -Mode 'Telnet'))

    $webSocketPort = Get-FreeTcpPort
    $webSocketProcess = Start-QingstoneServer -Mode 'WebSocket' -Port $webSocketPort -StateName 'websocket'
    $webSocket = Connect-WebSocketWithRetry -Port $webSocketPort -Origin 'http://127.0.0.1:8080'
    try {
        Send-WebSocketText -Socket $webSocket -Text '{"种类":"游客","请求编号":"e2e-guest","能力":["结构化消息-v1","请求编号","会话恢复"]}'
        $guest = Receive-WebSocketText -Socket $webSocket | ConvertFrom-Json
        if (-not $guest.成功 -or -not $guest.数据.恢复令牌) { throw 'WebSocket 游客会话未建立' }
        Send-WebSocketText -Socket $webSocket -Text '{"种类":"命令","请求编号":"e2e-look","命令":"观察"}'
        $look = Receive-WebSocketText -Socket $webSocket | ConvertFrom-Json
        if (-not $look.成功 -or $look.消息.Count -lt 1) { throw 'WebSocket 真实游戏命令未返回结构化消息' }
        Send-WebSocketText -Socket $webSocket -Text '{"种类":"退出","请求编号":"e2e-exit"}'
        $exit = Receive-WebSocketText -Socket $webSocket | ConvertFrom-Json
        if (-not $exit.成功) { throw 'WebSocket 会话退出失败' }
    }
    finally {
        $webSocket.Dispose()
    }
    $results.Add((Complete-QingstoneServer -Process $webSocketProcess -Mode 'WebSocket'))

    $httpPort = Get-FreeTcpPort
    $httpProcess = Start-QingstoneServer -Mode 'HTTP' -Port $httpPort -StateName 'http' -WebSocketUrl "ws://127.0.0.1:$webSocketPort/ws"
    $health = Invoke-HttpWithRetry -Port $httpPort
    try {
        if (-not $health.IsSuccessStatusCode) { throw "HTTP 健康检查失败：$([int]$health.StatusCode)" }
        $healthBody = $health.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
        if (-not $healthBody.成功 -or $healthBody.数据.状态 -ne 'healthy') { throw 'HTTP 健康检查响应无效' }
        if (-not $health.Headers.Contains('Content-Security-Policy')) { throw 'HTTP 响应缺少内容安全策略' }
    }
    finally {
        $health.Dispose()
    }
    $results.Add((Complete-QingstoneServer -Process $httpProcess -Mode 'HTTP'))

    [ordered]@{
        protocol = '言域/网络E2E'
        version = 1
        success = $true
        defaultStepBudget = $true
        transports = @($results)
    } | ConvertTo-Json -Depth 8 -Compress

    $completed = $true
}
catch {
    $diagnostics = [System.Collections.Generic.List[string]]::new()
    foreach ($process in $processes) {
        if (-not $process.HasExited) {
            $process.Kill($true)
            $process.WaitForExit(5000) | Out-Null
        }
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $diagnostics.Add("PID $($process.Id) exit $($process.ExitCode)`nstdout: $stdout`nstderr: $stderr")
    }
    throw "$($_.Exception.Message)`n子进程诊断：`n$($diagnostics -join "`n---`n")`n保留目录：$stateRoot"
}
finally {
    foreach ($process in $processes) {
        if (-not $process.HasExited) {
            $process.Kill($true)
            $process.WaitForExit(5000) | Out-Null
        }
        $process.Dispose()
    }
    if ($completed -and (Test-Path -LiteralPath $stateRoot)) {
        Remove-Item -LiteralPath $stateRoot -Recurse -Force
    }
}
