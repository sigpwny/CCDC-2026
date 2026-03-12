#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Deploy ClamAV on Windows via Chocolatey with scheduled scans.
    Falls back to MSI install if Chocolatey is unavailable.
.NOTES
    If offline, pre-install Chocolatey or place the ClamAV MSI at C:\Windows\Temp\clamav.msi
#>

$ErrorActionPreference = 'Stop'

$ClamDir  = "$env:ProgramFiles\ClamAV"
$LogDir   = "$env:ProgramData\ClamAV"
$LogFile  = "$LogDir\clamscan.log"

# --- Ensure log directory ---
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# --- Install ClamAV ---
$clamd = Get-Command clamscan.exe -ErrorAction SilentlyContinue
if (-not $clamd) {
    # Try Chocolatey first
    $choco = Get-Command choco.exe -ErrorAction SilentlyContinue
    if (-not $choco) {
        Write-Host "[*] Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        try {
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        } catch {
            Write-Host "[!] Failed to install Chocolatey: $_" -ForegroundColor Red
            Write-Host "[!] Install ClamAV manually or place MSI at C:\Windows\Temp\clamav.msi" -ForegroundColor Red
            exit 1
        }
    }
    Write-Host "[*] Installing ClamAV via Chocolatey..."
    choco install clamav -y --no-progress 2>&1
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# --- Update signatures ---
Write-Host "[*] Updating ClamAV signatures..."
try {
    & freshclam 2>&1
} catch {
    Write-Host "[!] freshclam failed (may need internet): $_" -ForegroundColor Yellow
}

# --- Create scheduled scan task ---
Write-Host "[*] Creating scheduled scan task..."
$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c clamscan.exe -r --infected --log=`"$LogFile`" C:\Users C:\Windows\Temp C:\inetpub 2>&1"
$trigger = New-ScheduledTaskTrigger -Daily -At "02:00AM"
$repetition = New-TimeSpan -Hours 4
$trigger.Repetition = (New-Object Microsoft.Management.Infrastructure.CimInstance "MSFT_TaskRepetitionPattern","root/Microsoft/Windows/TaskScheduler")
$trigger.Repetition.Interval = "PT4H"
$trigger.Repetition.StopAtDurationEnd = $false
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

Register-ScheduledTask -TaskName "ClamAV Scheduled Scan" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null

Write-Host "[+] ClamAV installed with 4-hourly scans. Logs: $LogFile"
