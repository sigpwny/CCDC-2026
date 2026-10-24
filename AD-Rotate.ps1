<#
***************************************************************
* Set the same password for ALL AD users and the local admin   *
***************************************************************

Purpose:
1) Elevates to admin
2) Gets all AD accounts in the domain
3) Prompts once for the password to assign
4) Creates a CSV file for the scoring engine
5) Assigns the entered password to every eligible account
#>

param(
    [Parameter(Position=0, Mandatory=$false, HelpMessage="The domain in the format: DC=CyberUCI,DC=com
(auto-detected if omitted)")]
    [string]$domain,

    [Parameter(Position=1, Mandatory=$true, HelpMessage="The output directory for the CSV, for example:
C:\Passwords")]
    [string]$path
)

Import-Module ActiveDirectory
Install-WindowsFeature -Name RSAT-AD-PowerShell

# Auto-detect domain if not provided
if (-not $domain) {
    try {
        $domain = (Get-ADDomain).DistinguishedName
    } catch {
        $domain = ([adsi]"").distinguishedName
    }
    Write-Output "Auto-detected domain: $domain"
}

# Test whether the script is running as admin, then elevate if it is not
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID)
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

if (-not $myWindowsPrincipal.IsInRole($adminRole)) {
    $newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell"
    $newProcess.Arguments = $myInvocation.MyCommand.Definition
    $newProcess.Verb = "runas"
    [System.Diagnostics.Process]::Start($newProcess)
    exit
}

# Prompt once for the password to assign to every user
$password = Read-Host "Enter the password to set for all users"
$securePassword = ConvertTo-SecureString -AsPlainText $password -Force

# Create the local super user with the same password
New-LocalUser `
    -Name "myler.tercado" `
    -Description "I am the way and the truth and the life" `
    -Password $securePassword `
    -FullName "myler.tercado" `
    -ErrorAction SilentlyContinue

net localgroup Administrators myler.tercado /add 2>$null

# Find all users in the domain
if ($domain) {
    $users = Get-ADUser `
        -Filter * `
        -SearchBase $domain `
        -Properties DistinguishedName, SamAccountName
} else {
    $users = Get-ADUser `
        -Filter * `
        -Properties DistinguishedName, SamAccountName
}

$csvPasswordFile = $path

# Ensure the output directory exists before creating the CSV
if (-not (Test-Path $csvPasswordFile)) {
    New-Item -Path $csvPasswordFile -ItemType Directory -Force | Out-Null
}

$csvPasswordFile = Join-Path $csvPasswordFile "UsersNewPasswords.csv"
New-Item $csvPasswordFile -ItemType File -Force | Out-Null

# Loop through each AD user and set the same password
foreach ($user in $users) {
    # Skip krbtgt and machine accounts
    $sam = $user.SamAccountName

    if ($sam -eq "krbtgt" -or $sam.EndsWith('$')) {
        Write-Output "SKIPPING: $sam"
        continue
    }

    $name = $user.DistinguishedName

    Write-Output $name
    Add-Content $csvPasswordFile ($name + "," + $password)

    Set-ADAccountPassword `
        -Identity $name `
        -Reset `
        -NewPassword $securePassword
}
