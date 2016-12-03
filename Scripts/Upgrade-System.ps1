<#
.SYNOPSIS
    A small wrapper for choco upgrade all -y (or cup all -y) to prevent my PowerShell profile from getting tampered with
.DESCRIPTION
    A small wrapper for choco upgrade all -y (or cup all -y) to prevent my PowerShell profile from getting tampered with
.PARAMETER WhatIf
    Show applications which would get upgraded.
.EXAMPLE
    Upgrade-System

    Description
    -------------
    Updates system packages using chocolatey
.NOTES
       Author: Zachary Loeber
       Site: http://www.the-little-things.net/
       Requires: Powershell 3.0

       Version History
       1.0.0 - Initial release
#>
[CmdletBinding()]
Param (
    [Parameter(HelpMessage = 'Show applications which would get upgraded.')]
    [switch]$WhatIf
)

$SourceDir = Split-Path $Profile
$SourceFile = Split-Path -Leaf $PROFILE

try {
    $null = get-command cup -ErrorAction:Stop
}
catch {
    Write-Output 'Chocolatey is not installed!'
    Write-Output 'You can install it by running the following: '
    Write-Output "  iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))"
    return
}

if (-not $WhatIf) {
    Write-Host -ForegroundColor Magenta 'Backing up the existing PowerShell profile before upgrading software'
    Write-Host -ForegroundColor Magenta 'This is largely to prevent some packages (posh-git) messing around with it.'
    Write-Host -ForegroundColor Magenta 'The profile script name will change to Profile.backup temporarily...'

    Rename-Item -Path $PROFILE -NewName 'Profile.backup'
    Write-Host -ForegroundColor Magenta 'Press any key to start a full upgrade of software on this system'
    Pause
    choco upgrade all -y
    Write-Host -ForegroundColor Magenta 'The profile script name will now be changed back after we remove any newly created profiles.'
    if (Test-Path $PROFILE) {
        Remove-Item $Profile -Confirm
    }
    Rename-Item -Path "$($SourceDir)\Profile.backup" -NewName $SourceFile
}
else {
    choco upgrade all -noop | Select-String -NotMatch "is the latest version"
}