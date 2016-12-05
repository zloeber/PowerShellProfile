<#
.SYNOPSIS
Attempts to sign the specified PowerShell scripts.
.DESCRIPTION
Attempts to sign the specified PowerShell scripts.
.PARAMETER Path
Path or script you want to try and digitally sign.
.PARAMETER Recurse
Recurse through all subdirectories of the path provided.
.PARAMETER Force
Attempts to sign the script even if it is already properly signed.
.PARAMETER UsePFX
Use the specified PFX file, otherwise the first found code signing certificate for the current user will be used.
.PARAMETER PFX
A valid path to a PFX file to use for code signing. Ignored if UsePFX is not used.
.EXAMPLE
PS> Set-ScriptSignature

Attempts to sign all powershell file sin  in the current path with the first code signing certificate found in the current users certificate store.

.NOTES
Author: Zachary Loeber
.LINK
http://www.the-little-things.net
#>

[CmdletBinding( SupportsShouldProcess = $true )]
Param (
    [Parameter(ValueFromPipeline = $True,ValueFromPipelineByPropertyName = $True)]
    [Alias('FilePath')]
    [string]$Path = $(Get-Location).Path,
    [Parameter()]
    [switch]$Recurse,
    [Parameter()]
    [switch]$Force,
    [Parameter()]
    [switch]$UsePFX,
    [Parameter()]
    [string]$PFX = ("$(Split-Path $PROFILE)\codesigningcert.pfx")
)
Begin {
    $RecurseParam = @{}
    if ($Recurse) {
        $RecurseParam.Recurse = $true
    }
    if ($UsePFX) {
        if (Test-Path $PFX) {
            Write-Verbose "Attempting to load the pfx file $PFX"
            try {
                $CodeSigningCert = Get-PfxCertificate $PFX
                Write-Verbose "PFX certificate loaded, thumbprint = $($CodeSigningCert.thumbprint)"
            }
            catch {
                Write-Error 'Unable to load PFX file!'
                return
            }
        }
        else {
            Write-Error "$PFX file not found!"
            return
        }
    }
    else {
        $CodeSigningCerts = @(get-childitem cert:\CurrentUser\My -codesigning -ErrorAction Stop)
        if ($CodeSigningCerts.Count -eq 0) {
            Write-Error 'No code signing certs found!'
            return
        }
        if ($CodeSigningCerts.Count -ne 1) {
            Write-Output "More than one code signing certificate found, using the first one in the list."
        }
        $CodeSigningCert = $CodeSigningCerts[0]
    }
}

Process {
    $FilesToProcess = Get-ChildItem -Path $Path -File -Include '*.psm1','*.ps1','*.psd1','*.ps1xml' @RecurseParam
    
    $FilesToProcess | ForEach-Object -Process {
        $SignatureStatus = (Get-AuthenticodeSignature $_).Status
        $ScriptFileFullName = $_.FullName
        Write-Output "$ScriptFileFullName -> Current signed status = $SignatureStatus"
        if ($Force -or ('HashMismatch', 'NotSigned', 'UnknownError' -contains $SignatureStatus)) {
            if ($pscmdlet.ShouldProcess( "Would attempt to update $ScriptFileFullName with your signing certificate.")) {
                Write-Output "$ScriptFileFullName -> Attempting to sign the script..."
                try {
                    $Null = Set-AuthenticodeSignature -FilePath $ScriptFileFullName -Certificate $CodeSigningCert -ErrorAction:Stop
                    Write-Output "$ScriptFileFullName -> Now Signed!"
                }
                catch {
                    Write-Error -Message $_.Exception.Message
                }
            }
        }
        else {
            Write-Output "$ScriptFileFullName -> Not signing as it is already signed without any detected issues."
        }
    }
}