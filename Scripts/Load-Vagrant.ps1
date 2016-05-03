Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

try {
    Import-Module vagrant-status

    function prompt {
        Write-Host($pwd.ProviderPath) -nonewline
        Write-VagrantStatusDetailed
        return "> "
    }
}
catch {}

Pop-Location
