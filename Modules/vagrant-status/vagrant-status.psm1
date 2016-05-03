if (Get-Module vagrant-status)
{
    return
}

Push-Location $PSScriptRoot
. .\VagrantUtils.ps1
Pop-Location

Export-ModuleMember -Function Get-VagrantFile, Get-VagrantDir, Get-VagrantEnvIndex, Write-VagrantStatusSimple, Write-VagrantStatusDetailed
