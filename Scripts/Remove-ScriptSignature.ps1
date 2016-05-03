[CmdletBinding()]
Param (
    [Parameter(position=0)]
    [string]$signedFile 
)
$filecontent = Get-Content $signedFile
$filecontent[0..(((Get-Content $signedFile | 
    select-string "SIG # Begin signature block").LineNumber)-2)] |
    Set-Content $signedFile