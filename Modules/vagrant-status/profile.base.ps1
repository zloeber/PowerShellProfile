Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

Import-Module .\vagrant-status

function prompt {
    Write-Host($pwd.ProviderPath) -nonewline
    Write-VagrantStatusDetailed
    return "> "
}

Pop-Location
