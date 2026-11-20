# Moonshard helyi szerver a helyi hálózaton (pl. telefonról): a lime csomagolt node-jával a scripts/devserver.js-t indítja 0.0.0.0-n (statikus kiszolgálás + élő napló),
# kiírja a hálózati címeket, és jelzi, ha a Windows tűzfal valószínűleg blokkolja a bejövő kapcsolatot.
#   powershell -ExecutionPolicy Bypass -File scripts/serve-lan.ps1 [-Port 3000] [-OpenFirewall]
# -OpenFirewall: bejövő TCP szabályt vesz fel a porthoz (rendszergazdai PowerShell kell hozzá, a Public profilra is).
# Leállítás: Ctrl+C.
param([int]$Port = 3000, [switch]$OpenFirewall)

$root = Split-Path -Parent $PSScriptRoot
$bin = Join-Path $root "export\html5\bin"
if (-not (Test-Path (Join-Path $bin "index.html"))) {
    Write-Host "Nincs fordított html5 build: futtasd előbb a 'haxelib run lime build html5' parancsot." -ForegroundColor Red
    exit 1
}

# A lime sablonmappájából a node és a http-server
$limePath = (haxelib libpath lime).Trim()
$node = Join-Path $limePath "templates\bin\node\node-windows.exe"
if (-not (Test-Path $node)) {
    Write-Host "A lime csomagolt node nem található itt: $limePath" -ForegroundColor Red
    exit 1
}

if ($OpenFirewall) {
    try {
        New-NetFirewallRule -DisplayName "Moonshard dev server ($Port)" -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow -Profile Any -ErrorAction Stop | Out-Null
        Write-Host "Tűzfalszabály felvéve a $Port TCP portra." -ForegroundColor Green
    }
    catch {
        Write-Host "A tűzfalszabály nem vehető fel (rendszergazdai PowerShell kell): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Foglalt-e a port? (egy másik szerver, pl. csak 127.0.0.1-re kötve, elvenné a kapcsolatot)
$busy = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
if ($busy) {
    Write-Host "A $Port port már foglalt (PID: $(($busy | Select-Object -ExpandProperty OwningProcess -Unique) -join ', ')): állítsd le a másik szervert, vagy adj meg másik portot (-Port 3001)." -ForegroundColor Red
    exit 1
}

$ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" -and $_.PrefixOrigin -ne "WellKnown" }
Write-Host ""
Write-Host "Telefonról (ugyanarról a Wi-Fi-ről) nyisd meg:" -ForegroundColor Cyan
foreach ($ip in $ips) { Write-Host "  http://$($ip.IPAddress):$Port/   ($($ip.InterfaceAlias))" }
Write-Host "Ha nem tölt be: a Windows tűzfal blokkolhatja. Futtasd -OpenFirewall kapcsolóval (rendszergazdaként), vagy állítsd a hálózatot 'Private'-ra." -ForegroundColor DarkGray
Write-Host ""

Write-Host "Élő napló a telefonról: add az URL-hez a ?log=1 paramétert (pl. http://<gép-IP>:$Port/?log=1)" -ForegroundColor Cyan
Write-Host ""
& $node (Join-Path $PSScriptRoot "devserver.js") $bin $Port
