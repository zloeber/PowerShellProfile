if($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Warning "vagrant-status requires PowerShell 3.0 or later."
    return
}

if(!(Test-Path $PROFILE)) {
    Write-Host "Creating PowerShell profile...`n$PROFILE"
    New-Item $PROFILE -Force -Type File -ErrorAction Stop > $null
}

$installDir = Split-Path $MyInvocation.MyCommand.Path -Parent

$profileLine = ". '$installDir\profile.base.ps1'"
if(Select-String -Path $PROFILE -Pattern $profileLine -Quiet -SimpleMatch) {
    Write-Host "It seems vagrant-status is already installed..."
    return
}

Write-Host "Adding vagrant-status to profile..."
@"

# Load default profile
$profileLine

"@ | Out-File $PROFILE -Append -Encoding Default

Write-Host 'vagrant-status installed reload to see changes'
