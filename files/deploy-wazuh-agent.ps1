#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Downloads and installs the Wazuh agent.
.PARAMETER ManagerIP
    IP address of the Wazuh manager.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ManagerIP,
    [string]$WazuhVersion = "4.9.0-1",
    [string]$MsiUrl = ""
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if ($MsiUrl -eq "") {
    $MsiUrl = "https://packages.wazuh.com/4.x/windows/wazuh-agent-${WazuhVersion}.msi"
}

# Check if already installed
$svc = Get-Service -Name Wazuh -ErrorAction SilentlyContinue
if ($svc) {
    Write-Host "[*] Wazuh agent already installed - updating manager IP..."
    $confPath = "${env:ProgramFiles(x86)}\ossec-agent\ossec.conf"
    if (Test-Path $confPath) {
        $conf = Get-Content $confPath -Raw
        $conf = $conf -replace '<address>.*?</address>', "<address>$ManagerIP</address>"
        Set-Content -Path $confPath -Value $conf -Force
    }
    NET STOP Wazuh 2>$null
    NET START Wazuh
    Write-Host "[+] Wazuh agent restarted with manager $ManagerIP"
    exit 0
}

$MsiPath = "$env:TEMP\wazuh-agent.msi"

Write-Host "[*] Downloading Wazuh agent MSI..."
Invoke-WebRequest -Uri $MsiUrl -OutFile $MsiPath

Write-Host "[*] Installing Wazuh agent (manager=$ManagerIP)..."
Start-Process msiexec.exe -ArgumentList "/i `"$MsiPath`" /q WAZUH_MANAGER=`"$ManagerIP`"" -Wait -NoNewWindow

Start-Sleep -Seconds 5
NET START Wazuh

Remove-Item $MsiPath -Force -ErrorAction SilentlyContinue
Write-Host "[+] Wazuh agent installed and connected to $ManagerIP"
