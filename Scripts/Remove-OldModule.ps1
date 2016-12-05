#Requires -Version 5

<#
.SYNOPSIS
    A small wrapper for PowerShellGet to remove all older installed modules.
.DESCRIPTION
    A small wrapper for PowerShellGet to remove all older installed modules.
.PARAMETER ModuleName
    Name of a module to check and remove old versions of.
.EXAMPLE
    Remove-OldModules.ps1

    Description
    -------------
    Removes old modules installed via PowerShellGet.
.NOTES
       Author: Zachary Loeber
       Site: http://www.the-little-things.net/
       Requires: Powershell 5.0

       Version History
       1.0.0 - Initial release
#>
[CmdletBinding( SupportsShouldProcess = $true )]
Param (
    [Parameter(HelpMessage = 'Name of a module to check and remove old versions of.')]
    [string]$ModuleName = '*'
)

try {
    Import-Module PowerShellGet
}
catch {
    Write-Warning 'Unable to load PowerShellGet. This script only works with PowerShell 5 and greater.'
    return
}
$WhatIfParam = @{}
$WhatIfParam.WhatIf = $WhatIf
Get-InstalledModule $ModuleName | foreach {
    $InstalledModules = get-module $_.Name -ListAvailable
    if ($InstalledModules.Count -gt 1) {
        $SortedModules = $InstalledModules | sort-object Version -Descending
        Write-Output "Multiple Module versions for the $($SortedModules[0].Name) module found. Highest version is: $($SortedModules[0].Version.ToString())"
        for ($index = 1; $index -lt $SortedModules.Count; $index++) {
            try {
                if ($pscmdlet.ShouldProcess( "$($SortedModules[$index].Name) - $($SortedModules[$index].Version)")) {
                    Write-Output "..Attempting to uninstall $($SortedModules[$index].Name) - Version $($SortedModules[$index].Version)"
                    Uninstall-Module -Name $SortedModules[$index].Name -MaximumVersion $SortedModules[$index].Version -ErrorAction Stop -Force
                }
            }
            catch {
                Write-Warning "Unable to remove module version $($SortedModules[$index].Version)"
            }
        }
    }
}