<#
.SYNOPSIS
Finds all signed ps1 and psm1 files recursively from the current  or defined path and removes any digital signatures attached to them.
.DESCRIPTION
Finds all signed ps1 and psm1 files recursively from the current  or defined path and removes any digital signatures attached to them.
.PARAMETER Path
Path you want to parse for digital signatures.
.EXAMPLE
UnsignAllScripts.ps1

Description
-------------
Removes all digital signatures from ps1/psm1 files found in the current path.

.NOTES
Author: Zachary Loeber
.LINK
http://www.the-little-things.net
#>

[CmdletBinding()]
Param (
    [Parameter(position=0)]
    [string]$Path = $(Get-Location).Path
) 
Get-ChildItem -Path $Path -File -Include '*.psm1','*.ps1' -Recurse | Get-AuthenticodeSignature | Where {$_.Status -ne 'NotSigned'} | Foreach {
    $scriptpath = $_.Path
    $filecontent = Get-Content $scriptpath
    $filecontent[0..(((Get-Content $scriptpath | select-string "SIG # Begin signature block").LineNumber)-2)] | Set-Content $scriptpath
    Write-Output "Removed signature from - $($scriptpath)"           
}
