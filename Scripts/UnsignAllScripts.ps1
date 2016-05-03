# finds all signed ps1 and psm1 files recursively from the current path and removes the signature 
Get-ChildItem -File -Include '*.psm1','*.ps1' -Recurse | Get-AuthenticodeSignature | Where {$_.Status -ne 'NotSigned'} | Foreach {
    $scriptpath = $_.Path
    $filecontent = Get-Content $scriptpath
    $filecontent[0..(((Get-Content $scriptpath | select-string "SIG # Begin signature block").LineNumber)-2)] | Set-Content $scriptpath
    Write-Output "Removed signature from - $($scriptpath)"           
}