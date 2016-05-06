# Run this in an administrative PowerShell prompt to install the PowerShell profile
#
# 	iex (New-Object Net.WebClient).DownloadString("https://raw.githubusercontent.com/zloeber/PowerShellProfile/master/Install.ps1")

# Some general variables
$ProjectName = 'PowerShellProfile'
$GithubURL = 'https://github.com/zloeber/PowerShellProfile'
$InstallPath = Split-Path $PROFILE

# Download and install
$webclient = New-Object System.Net.WebClient
$url = "$GithubURL/archive/master.zip"
Write-Host "Downloading latest version of PowerShellProfile from $url" -ForegroundColor Cyan
$file = "$($env:TEMP)\$($ProjectName).zip"
$webclient.DownloadFile($url,$file)
Write-Host "File saved to $file" -ForegroundColor Green
$targetondisk = "$(Split-Path $PROFILE)"
New-Item -ItemType Directory -Force -Path $targetondisk | out-null
$shell_app=new-object -com shell.application
$zip_file = $shell_app.namespace($file)
Write-Host "Uncompressing the Zip file to $($targetondisk)" -ForegroundColor Cyan
$destination = $shell_app.namespace($targetondisk)
$destination.Copyhere($zip_file.items(), 0x10)
Write-Host "Renaming folder" -ForegroundColor Cyan

if (Test-Path "$targetondisk\$($ProjectName)") { Remove-Item -Force "$targetondisk\$($ProjectName)" -Confirm:$false }
Rename-Item -Path ($targetondisk+"\$($ProjectName)-master") -NewName "$ProjectName" -Force

if (Test-Path $PROFILE) {
    $currentprofiles = Get-ChildItem -Path "$($installpath)\Microsoft.PowerShell_profile.*"
    if ($currentprofiles.count -gt 0) {
        $BackupProfileName = "$($installpath)\Microsoft.PowerShell_profile.old$($currentprofiles.count)"
        Write-Host -ForegroundColor:Yellow "Microsoft.PowerShell_profile.ps1 already exists, renaming it to $($BackupProfileName)"
        Rename-Item $PROFILE -NewName $BackupProfileName
    }
}

Copy-Item "$($targetondisk)\$($ProjectName)\Microsoft.PowerShell_profile.ps1" -Destination $InstallPath

if (Test-Path "$($InstallPath)\Scripts") {
    Write-Host ''
    Write-Warning "$($InstallPath)\Scripts already exists! To fully install this script please copy the scripts from $($targetondisk)\$($ProjectName)\Scripts to this directory."
    Write-Host ''
}
else {
    Copy-Item "$($targetondisk)\$($ProjectName)\Scripts" -Destination "$($InstallPath)\Scripts" -Recurse
}

if (Test-Path "$($InstallPath)\Data\quotes.txt") {
    Write-Warning "$($InstallPath)\Data\quotes.txt already exists! To fully install this script please copy the scripts from $($targetondisk)\$($ProjectName)\Data to this directory."
}
else {
    Copy-Item -Path "$($targetondisk)\$($ProjectName)\Data" -Destination "$($InstallPath)" -Recurse
}

Copy-Item -Confirm $true -Path "$($targetondisk)\$($ProjectName)\Modules" -Destination "$($InstallPath)\Modules" -Recurse

Write-Host "Profile has been installed" -ForegroundColor Green
Write-Host "Optionally create a code signing certificate and protect your profile with the following lines of code in a powershell prompt" -ForegroundColor Cyan
Write-Host "Note: You will get a security warning you will have to accept in order to trust the created certificate!" -ForegroundColor Cyan
Write-Host "New-CodeSigningCertificate.ps1" -ForegroundColor Cyan
Write-Host "Set-ProfileScriptSignature.ps1" -ForegroundColor Cyan
Write-Host "Set-ExecutionPolicy AllSigned" -ForegroundColor Cyan