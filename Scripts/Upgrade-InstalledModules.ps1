#Requires -Version 5

<#
.SYNOPSIS
    A small wrapper for PowerShellGet to upgrade all installed modules and scripts.
.DESCRIPTION
    A small wrapper for PowerShellGet to upgrade all installed modules and scripts.
.PARAMETER WhatIf
    Show modules which would get upgraded.
.EXAMPLE
    Upgrade-InstalledModules.ps1

    Description
    -------------
    Updates modules installed via PowerShellGet.
.NOTES
       Author: Zachary Loeber
       Site: http://www.the-little-things.net/
       Requires: Powershell 5.0

       Version History
       1.0.0 - Initial release
#>
[CmdletBinding()]
Param (
    [Parameter(HelpMessage = 'Show modules which would get upgraded.')]
    [switch]$WhatIf
)

try {
    Import-Module PowerShellGet
}
catch {
    Write-Warning 'Unable to load PowerShellGet. This script only works with PowerShell 5 and greater.'
    return
}

$WhatIfParam = @{WhatIf=$WhatIf}

Get-InstalledModule | Update-Module -Force @WhatIfParam
Get-InstalledScript | Update-Script @WhatIfParam