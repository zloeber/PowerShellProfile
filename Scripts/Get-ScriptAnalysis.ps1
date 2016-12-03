<#
    .SYNOPSIS
        Installs PSScriptAnalyzer module and runs it against a supplied path.
    .DESCRIPTION
        Installs PSScriptAnalyzer module and runs it against a supplied path.
    .PARAMETER ProjectPath
        Path to scripts to analyze.
    .EXAMPLE
        .\Get-ScriptAnalysis.ps1 -ProjectPath C:\Project1\
    .NOTES
       Author: Zachary Loeber
       Site: http://www.the-little-things.net/
       Requires: Powershell 5.0

       Version History
       1.0.0 - Initial release
    #>
[CmdletBinding()]
param(
    [parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage='Path of module to analyze.')]
    [string]$ProjectPath = (Read-Host -Prompt 'Please enter the script path to analyze')
)

# This assumes you are running PowerShell 5
if ($PSVersionTable.PSVersion.Major -ge 5) {
    if (Test-Path $ProjectPath) {
        if ( -not (get-module PSScriptAnalyzer)) {
            Install-Module -Name PSScriptAnalyzer -Repository PSGallery -force
        }
        if (get-module PSScriptAnalyzer) {
            try {
                Invoke-ScriptAnalyzer -Path $ProjectPath
            }
            catch {
                throw 'ScriptAnalyzer failed!'
            }
        } 
        else {
            Write-Error 'Unable to install PSScriptAnalyzer!'
        }
    }
    else {
        Write-Error 'Path to project was not found!'
    }
}
else {
    Write-Error 'This requires powershell version 5. Please see the requirements for PSScriptAnalyzer here: https://github.com/PowerShell/PSScriptAnalyzer'
}