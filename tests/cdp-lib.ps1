# Minimális Chrome DevTools Protocol kliens a fejnélküli Edge vezérléséhez (Node nélkül).
# Használat: . "$PSScriptRoot\cdp-lib.ps1"; Start-Cdp <url> <kimeneti-mappa>; Js "<kifejezés>"; ... ; Stop-Cdp
# A játékot teszt-buildben (`haxelib run lime build html5 -Dtest`) kell kiszolgálni, pl. az 3000-es porton.

$script:CdpWs = $null
$script:CdpProc = $null
$script:CdpOut = $null
$script:CdpId = 0

function Start-Cdp([string]$Url, [string]$OutDir) {
    $script:CdpOut = $OutDir
    New-Item -ItemType Directory -Force $OutDir | Out-Null
    $edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    if (-not (Test-Path $edge)) { $edge = "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe" }
    if (-not (Test-Path $edge)) { throw "Az Edge nem található." }
    $profile = Join-Path $OutDir "edge-cdp"
    $script:CdpProc = Start-Process $edge -ArgumentList "--headless=new", "--remote-debugging-port=9333", "--window-size=960,540", "--hide-scrollbars", "--user-data-dir=$profile", "about:blank" -PassThru
    Start-Sleep -Seconds 3
    $page = (Invoke-RestMethod "http://127.0.0.1:9333/json") | Where-Object { $_.type -eq "page" } | Select-Object -First 1
    $script:CdpWs = New-Object System.Net.WebSockets.ClientWebSocket
    $script:CdpWs.Options.KeepAliveInterval = [TimeSpan]::FromSeconds(30)
    $script:CdpWs.ConnectAsync([Uri]$page.webSocketDebuggerUrl, [Threading.CancellationToken]::None).Wait()
    Send-Cdp "Page.enable" @{} | Out-Null
    Send-Cdp "Network.enable" @{} | Out-Null
    Send-Cdp "Network.setCacheDisabled" @{ cacheDisabled = $true } | Out-Null
    # JS-hibák gyűjtése: window.__errors
    Send-Cdp "Page.addScriptToEvaluateOnNewDocument" @{ source = "window.__errors = []; window.addEventListener('error', e => window.__errors.push(String(e.message)));" } | Out-Null
    Send-Cdp "Page.navigate" @{ url = $Url } | Out-Null
}

function Stop-Cdp {
    if ($script:CdpWs) { $script:CdpWs.Dispose() }
    if ($script:CdpProc) { Stop-Process -Id $script:CdpProc.Id -Force -ErrorAction SilentlyContinue }
    # Csak a saját (külön profilos) headless példány folyamatai
    Get-CimInstance Win32_Process -Filter "Name = 'msedge.exe'" | Where-Object { $_.CommandLine -like "*edge-cdp*" } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

function Send-Cdp($method, $params) {
    $script:CdpId++
    $id = $script:CdpId
    $json = @{ id = $id; method = $method; params = $params } | ConvertTo-Json -Depth 10 -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $script:CdpWs.SendAsync([ArraySegment[byte]]$bytes, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [Threading.CancellationToken]::None).Wait()
    while ($true) {
        $ms = New-Object IO.MemoryStream
        do {
            $buf = New-Object byte[] 65536
            $r = $script:CdpWs.ReceiveAsync([ArraySegment[byte]]$buf, [Threading.CancellationToken]::None).Result
            $ms.Write($buf, 0, $r.Count)
        } while (-not $r.EndOfMessage)
        $msg = [Text.Encoding]::UTF8.GetString($ms.ToArray()) | ConvertFrom-Json
        if ($msg.id -eq $id) { return $msg }
    }
}

# JS kiértékelése; az eredményt PowerShell-objektumként adja vissza, kivétel esetén hibát dob
function Js($expr) {
    $r = Send-Cdp "Runtime.evaluate" @{ expression = $expr; returnByValue = $true; awaitPromise = $true }
    if ($r.result.exceptionDetails) { throw ("JS kivétel: " + ($r.result.exceptionDetails | ConvertTo-Json -Depth 5 -Compress)) }
    return $r.result.result.value
}

function Key($type, $key, $code, $vk) {
    Send-Cdp "Input.dispatchKeyEvent" @{ type = $type; key = $key; code = $code; windowsVirtualKeyCode = $vk; nativeVirtualKeyCode = $vk } | Out-Null
}

function Shot($name) {
    $r = Send-Cdp "Page.captureScreenshot" @{ format = "png" }
    [IO.File]::WriteAllBytes((Join-Path $script:CdpOut $name), [Convert]::FromBase64String($r.result.data))
}
