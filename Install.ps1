# Run this in an administrative PowerShell prompt to install the PowerShell profile
#
# 	iex (New-Object Net.WebClient).DownloadString("https://raw.githubusercontent.com/zloeber/PowerShellProfile/master/Install.ps1")

# Some general variables
$ProjectName = 'PowerShellProfile'
$GithubURL = 'https://github.com/zloeber/PowerShellProfile'
$InstallPath = Split-Path $PROFILE
$file = "$($env:TEMP)\$($ProjectName).zip"
$url = "$GithubURL/archive/master.zip"
$targetondisk = $env:TEMP
$SourcePath =  ($targetondisk+"\$($ProjectName)-master")

if (Test-Path $file) {
    Write-Host -ForegroundColor:DarkYellow 'Prior download already exists, deleting it!'
    Remove-Item -Force -Path $file -Confirm:$false
}

# Download and install the zip file to a temp directory and rename it
$webclient = New-Object System.Net.WebClient
Write-Host "Downloading latest version of PowerShellProfile from $url" -ForegroundColor Cyan
$webclient.DownloadFile($url,$file)
Write-Host "File saved to $file" -ForegroundColor Green

$shell_app=new-object -com shell.application
$zip_file = $shell_app.namespace($file)

if (Test-Path $SourcePath) {
    Write-Host -ForegroundColor:DarkYellow 'Prior download directory already exists, deleting it!'
    Remove-Item -Force -Path  $SourcePath -Confirm:$false
}
Write-Host "Uncompressing the Zip file to $($targetondisk)" -ForegroundColor Cyan
$destination = $shell_app.namespace($targetondisk)
$destination.Copyhere($zip_file.items(), 0x10)

if (Test-Path $PROFILE) {
    $currentprofiles = Get-ChildItem -Path "$($installpath)\Microsoft.PowerShell_profile.*"
    if ($currentprofiles.count -gt 0) {
        $BackupProfileName = "$($installpath)\Microsoft.PowerShell_profile.old$($currentprofiles.count)"
        Write-Host -ForegroundColor:Yellow "Microsoft.PowerShell_profile.ps1 already exists, renaming it to $($BackupProfileName)"
        Rename-Item $PROFILE -NewName $BackupProfileName
    }
}

Copy-Item "$($SourcePath)\Microsoft.PowerShell_profile.ps1" -Destination $InstallPath

if (Test-Path "$($InstallPath)\Scripts") {
    Write-Host -ForegroundColor Red  "$($InstallPath)\Scripts already exists! Be VERY careful before selecting to overwrite items within it at the next prompt!!!"
}
Copy-Item "$($SourcePath)\Scripts" -Destination "$($InstallPath)" -Recurse -Confirm -Force

if (Test-Path "$($InstallPath)\Data\quotes.txt") {
    Write-Warning "$($InstallPath)\Data\quotes.txt already exists! Be VERY careful before selecting to overwrite it in the next prompt!!!"
}
Copy-Item -Path "$($SourcePath)\Data" -Destination "$($InstallPath)" -Recurse -Force -Confirm

if (Test-Path "$($InstallPath)\Modules") {
    Write-Warning "$($InstallPath)\Modules already exists! Be VERY careful before selecting to overwrite items within it at the next prompt!!!"
}
Copy-Item -Path "$($SourcePath)\Modules" -Destination "$($InstallPath)\Modules" -Recurse -Force -Confirm

Write-Host ''
Write-Host "Your new Powershell profile has been installed." -ForegroundColor Green
Write-Host "The default persistent history will be 250 lines. This and anything else in the profile can be changed in the following file:" -ForegroundColor Green
Write-Host "     $($InstallPath)\Microsoft.PowerShell_profile.ps1"
Write-Host ''
Write-Host 'The profile script is currently not signed and thus can be suspect to tampering without you knowing'  -ForegroundColor Green
Write-Host "Optionally create a code signing certificate and protect your profile with the following lines of code in a powershell prompt" -ForegroundColor Green
Write-Host "( Note: You may get a security warning you will have to accept in order to trust the created certificate! )" -ForegroundColor Cyan
Write-Host ''
Write-Host "    $($InstallPath)\Scripts\New-CodeSigningCertificate.ps1" -ForegroundColor DarkGreen
Write-Host "    $($InstallPath)\Scripts\Set-ProfileScriptSignature.ps1" -ForegroundColor DarkGreen
Write-Host "    $($InstallPath)\Scripts\Set-ExecutionPolicy AllSigned" -ForegroundColor DarkGreen
Write-Host ''
Write-Host 'Enjoy your new PowerShell profile! (Remember you can hold the shift key while it loads to get more detailed information on what it is doing)' -ForegroundColor Green