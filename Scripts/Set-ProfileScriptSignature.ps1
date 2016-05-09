<#
    Re-run this if you have updated any scripts in your profile this script will attempt to sign the following files with the first available code signing certificate if 
    they are not in a currently valid signed state:
    - $Profile (Typically C:\Users\<userid>\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1)
    - "$(Split-Path $Profile)\Modules\Environment\Environment.psm1" (typically C:\Users\<userid>\Documents\WindowsPowerShell\Modules\Environment\Environment.psm1)
#>
[CmdletBinding()]
Param (
    [Parameter(position=0)]
    [string]$ScriptToSign,
    [Parameter(position=1)]
    [switch]$Secure,
    [Parameter(position=2)]
    [string]$PFX = ("$(Split-Path $PROFILE)\codesigningcert.pfx")
)
Begin {
    $ProfilePath = Split-Path $PROFILE
    if ([string]::isNullorEmpty($ScriptToSign)) {
        Write-Verbose 'No files specified so we will validate and update only the profile script and the environment.psm1 files.'
        $PSFiles = @()
        $ProfileFiles = "$(Split-Path $Profile)\Modules\Environment\Environment.psm1",$Profile
        $PSFiles = @()
        $ProfileFiles | Foreach {
            $PSFile = Get-ChildItem $_ -File
            $PSFiles += $PSFile
            Write-Verbose "File $($PSFile.Name) - $($PSFile.Status)"
        }
        #$PSFiles = Get-ChildItem -File -Recurse -path (Split-Path $Profile) -Include '*.ps1','*.psm1'
        $ScriptsToSign = @($PSFiles | Get-AuthenticodeSignature | Where-Object { 'HashMismatch', 'NotSigned', 'UnknownError' -contains $_.Status })
    }
    else {
        $ScriptsToSign = @($ScriptToSign | Get-AuthenticodeSignature)
    }
    if ($Secure) {
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
        $CodeSigningCerts = @(get-childitem cert:\CurrentUser\My -codesigning)
        if ($CodeSigningCerts.Count -eq 0) {
            Write-Error 'No code signing certs found!'
            return
        }
        if ($CodeSigningCerts.Count -ne 1) {
            Write-Verbose "More than one code signing certificate found, using the first one in the list."
        }
        $CodeSigningCert = $CodeSigningCerts[0]
    }
}
Process {}
End {
    $ScriptsToSign | foreach {
        Write-Output "The following script signed status is $($_.Status) - $($_.Path)"
        $Null = Set-AuthenticodeSignature $_.Path $CodeSigningCert
    }
}