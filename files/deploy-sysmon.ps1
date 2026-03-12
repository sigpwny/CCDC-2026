#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Downloads and installs Sysmon with a CCDC-tuned configuration.
.NOTES
    Run as Administrator. Downloads Sysmon from Microsoft and config from repo.
#>

param(
    [string]$InstallDir = "$env:ProgramFiles\Sysmon",
    [string]$SysmonUrl = "https://download.sysinternals.com/files/Sysmon.zip",
    [string]$ConfigUrl = "",
    [switch]$Update
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# --- Ensure install directory exists ---
if (-not (Test-Path $InstallDir)) {
    Write-Host "[*] Creating install directory: $InstallDir"
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

$SysmonExe  = Join-Path $InstallDir 'Sysmon64.exe'
$ConfigFile = Join-Path $InstallDir 'sysmonconfig.xml'
$ZipPath    = "$env:TEMP\Sysmon.zip"

# --- Download and extract Sysmon ---
if (-not (Test-Path $SysmonExe)) {
    Write-Host "[*] Downloading Sysmon..."
    Invoke-WebRequest -Uri $SysmonUrl -OutFile $ZipPath
    Write-Host "[*] Extracting Sysmon64.exe..."
    Expand-Archive -Path $ZipPath -DestinationPath $InstallDir -Force
    Remove-Item $ZipPath -Force
}

# --- Deploy config (use embedded if no URL provided) ---
if ($ConfigUrl -ne "") {
    Write-Host "[*] Downloading sysmonconfig.xml..."
    Invoke-WebRequest -Uri $ConfigUrl -OutFile $ConfigFile
} elseif (-not (Test-Path $ConfigFile)) {
    Write-Host "[!] No config URL provided and no config found at $ConfigFile"
    Write-Host "[!] Provide -ConfigUrl or place sysmonconfig.xml in $InstallDir"
    exit 1
}

# --- Install or Update Sysmon ---
$svc = Get-Service -Name Sysmon64 -ErrorAction SilentlyContinue
if ($svc) {
    Write-Host "[*] Sysmon already installed - updating config..."
    & $SysmonExe -c $ConfigFile
} else {
    Write-Host "[*] Installing Sysmon..."
    & $SysmonExe -accepteula -i $ConfigFile
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] Sysmon deployed successfully."
    Write-Host "[+] Events: Microsoft-Windows-Sysmon/Operational"
} else {
    Write-Error "[-] Sysmon installation failed with exit code $LASTEXITCODE"
}
