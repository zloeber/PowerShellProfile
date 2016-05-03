if ($session) { 
    Remove-PSSession $session
} else {
    Get-PSSession | Remove-PSSession
}

"$((Get-PSSession | Measure-Object).Count) PowerShell session(s)"
