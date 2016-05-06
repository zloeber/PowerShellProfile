<# 
 This whole profile is largely Joel Bennett's baby
 Original found here: http://poshcode.org/6062

 Features
 - History persistence between sessions
 - Some custom colors
 - Random quotes
 - Fun session banner
 - Several helper functions/scripts for such things as connectin to o365 or PowerCLI
 - Press and hold either Shift key while the session starts to display verbose output

 If you make changes to this then you probably want to re-sign it as well. The installer script accompanying this profile should have created a self-signed
 certificate which can be used with the Scripts\Set-ProfileScriptSignature.ps1 included with this profile as well. This script will re-sign ALL scripts in your
 profile (Consider yourself warned!) if run without parameters.
#>
trap { Write-Warning ($_.ScriptStackTrace | Out-String) }

# Some variables for later (that also get removed from memory at the end of this profile loading)
$PersistentHistoryCount = 500

# This timer is used by Trace-Message, I want to start it immediately
$Script:TraceVerboseTimer = New-Object System.Diagnostics.Stopwatch
$Script:TraceVerboseTimer.Start()

# PS5 introduced PSReadLine, which chokes in non-console shells, so I snuff it.
try {
    $NOCONSOLE = $FALSE
    [System.Console]::Clear()
}
catch {
    $NOCONSOLE = $TRUE
}

# If your PC doesn't have this set already, someone could tamper with this script...
# but at least now, they can't tamper with any of the modules/scripts that I auto-load!
Set-ExecutionPolicy AllSigned Process

if ((Get-ExecutionPolicy -list | Where {$_.Scope -eq 'LocalMachine'}).ExecutionPolicy -ne 'AllSigned') {
    Write-Warning 'Execution policy was set to AllSigned for this process but is not set to AllSigned for the LocalMachine. '
    Write-Warning 'What this means is that this profile could be tampered with and you might never know!'
}

# Ok, now import environment so we have PSProcessElevated, Trace-Message, and other custom functions we use later
# The others will get loaded automatically, but it's faster to load them explicitly
Import-Module $PSScriptRoot\Modules\Environment, Microsoft.PowerShell.Management, Microsoft.PowerShell.Security, Microsoft.PowerShell.Utility

# Check SHIFT state ASAP at startup so I can use that to control verbosity :)
Add-Type -Assembly PresentationCore, WindowsBase
try {
    $global:SHIFTED = [System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::LeftShift) -OR
                      [System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::RightShift)
}
catch {
    $global:SHIFTED = $false
}

# If SHIFT is pressed, use verbose output from here on
if($SHIFTED) { $VerbosePreference = "Continue" }

##  Fix colors before anything gets output.
if($Host.Name -eq "ConsoleHost") {
    $Host.PrivateData.ErrorForegroundColor    = "DarkRed"
    $Host.PrivateData.WarningForegroundColor  = "DarkYellow"
    $Host.PrivateData.DebugForegroundColor    = "Green"
    $Host.PrivateData.VerboseForegroundColor  = "Cyan"
    $Host.PrivateData.ProgressForegroundColor = "Yellow"
    $Host.PrivateData.ProgressBackgroundColor = "DarkMagenta"

}
elseif($Host.Name -eq "Windows PowerShell ISE Host") {
    $Host.PrivateData.ErrorForegroundColor    = "DarkRed"
    $Host.PrivateData.WarningForegroundColor  = "Gold"
    $Host.PrivateData.DebugForegroundColor    = "Green"
    $Host.PrivateData.VerboseForegroundColor  = "Cyan"
}

# First call to Trace-Message, pass in our TraceTimer that I created at the top to make sure we time EVERYTHING.
Trace-Message "Microsoft.PowerShell.* Modules Imported" -Stopwatch $TraceVerboseTimer

## Set the profile directory first, so we can refer to it from now on.
Set-Variable ProfileDir (Split-Path $MyInvocation.MyCommand.Path -Parent) -Scope Global -Option AllScope, Constant -ErrorAction SilentlyContinue

#Set-Variable LiveID (
#    [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups | Where-Object { $_.Value -match "^S-1-11-96" }
#).Translate([System.Security.Principal.NTAccount]).Value  -Scope Global -Option AllScope, Constant -ErrorAction SilentlyContinue

Set-Variable ReReverse @('(?sx) . (?<=(?:.(?=.*$(?<=((.) \1?))))*)', '$2') -Scope Global -Option AllScope, Constant -ErrorAction SilentlyContinue

<#
   Add additional items to your path. Modify this to suit your needs. 
   We do need the Scripts directory for the rest of this profile script to run though so this first one is essential to add.
#>
[string[]]$folders = Get-ChildItem $ProfileDir\Script[s] -Directory | % FullName

## Developer tools stuff ...
# $folders += [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
## MSBuild is now in 'C:\Program Files (x86)\MSBuild\{version}'
#$folders += Set-AliasToFirst -Alias "msbuild" -Path 'C:\Program Files (x86)\MSBuild\*\Bin\MsBuild.exe' -Description "Visual Studio's MsBuild" -Force -Passthru
#$folders += Set-AliasToFirst -Alias "merge" -Path "C:\Program*Files*\Perforce\p4merge.exe","C:\Program*Files*\DevTools\Perforce\p4merge.exe" -Description "Perforce" -Force -Passthru
#$folders += Set-AliasToFirst -Alias "tf" -Path "C:\Program*Files*\*Visual?Studio*\Common7\IDE\TF.exe", "C:\Program*Files*\DevTools\*Visual?Studio*\Common7\IDE\TF.exe" -Description "Visual Studio" -Force -Passthru
#$folders += Set-AliasToFirst -Alias "Python","Python2","py2" -Path "C:\Python2*\python.exe", "D:\Python2*\python.exe" -Description "Python 2.x" -Force -Passthru
#$folders += Set-AliasToFirst -Alias "Python3","py3" -Path "C:\Python3*\python.exe", "D:\Python3*\python.exe" -Description "Python 3.x" -Force -Passthru
#Set-AliasToFirst -Alias "iis","iisexpress" -Path 'C:\Progra*\IIS*\IISExpress.exe' -Description "Personal Profile Alias"
#Trace-Message "Development aliases set"
if ($SHIFTED) {
    Trace-Message "Path before updates: "
    $($ENV:Path -split ';') | Foreach {
        Trace-Message " -- $($_)"
    }
}

$ENV:PATH = Select-UniquePath $folders ${Env:Path}

if ($SHIFTED) {
    Trace-Message "Path AFTER updates: "
    $($ENV:Path -split ';') | Foreach {
        Trace-Message " -- $($_)"
    }
}
## Additional module directories to search for loading modules with Import-Module
$Env:PSModulePath = Select-UniquePath "$ProfileDir\Modules",(Get-SpecialFolder *Modules -Value),${Env:PSModulePath} #,"${Home}\Projects\Modules"
Trace-Message "PSModulePath Updated "

<#
   Custom aliases if you want them (some examples commented out)
#>
#Set-Alias   say Speech\Out-Speech         -Option Constant, ReadOnly, AllScope -Description "Personal Profile Alias"
#Set-Alias   gph Get-PerformanceHistory    -Option Constant, ReadOnly, AllScope -Description "Personal Profile Alias"

# Start sessions in the profile directory. If you need to go to the prior directory just pop-location right after starting powershell
if($ProfileDir -ne (Get-Location)) {
   Push-Location $ProfileDir
}

# Add some psdrives if you want them
New-PSDrive Documents FileSystem (Get-SpecialFolder MyDocuments -Value)

# I no longer worry about OneDrive, because I mapped my Documents into it, so there's only OneDrive
if( ($OneDrive = (Get-ItemProperty HKCU:\Software\Microsoft\OneDrive UserFolder -EA 0).UserFolder) -OR
    ($OneDrive = (Get-ItemProperty HKCU:\Software\Microsoft\SkyDrive UserFolder -EA 0).UserFolder) -OR
    ($OneDrive = (Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\SkyDrive UserFolder -EA 0).UserFolder)
  ) {
    New-PSDrive OneDrive FileSystem $OneDrive
    Trace-Message "OneDrive:\ mapped to $OneDrive"
}
if(Test-Path $Home\Projects) {
    New-PSDrive Projects FileSystem $Home\Projects
    New-PSDrive Modules FileSystem $Home\Projects\Modules
}

<#
   The prompt function is in it's own script, and executing it imports previous history
#>
if($Host.Name -ne "Package Manager Host") {
  Set-Prompt -Clean -PersistentHistoryCount $PersistentHistoryCount
  Trace-Message "Prompt fixed"
}

if($Host.Name -eq "ConsoleHost" -and !$NOCONSOLE) {
    if(-not (Get-Module PSReadLine)) { Import-Module PSReadLine }

    ## If you have history to reload, you must do that BEFORE you import PSReadLine
    ## That way, the "up arrow" navigation works on the previous session's commands
    function Set-PSReadLineMyWay {
        param(
            #$BackgroundColor = $(if($PSProcessElevated) { "DarkGray" } else { "Black" } )
            $BackgroundColor =  "Black"
        )
        $Host.UI.RawUI.BackgroundColor = $BackgroundColor
        $Host.UI.RawUI.ForegroundColor = "Gray"

        Set-PSReadlineOption -TokenKind Keyword -ForegroundColor Yellow -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind String -ForegroundColor Green -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Operator -ForegroundColor DarkGreen -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Variable -ForegroundColor DarkMagenta -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Command -ForegroundColor DarkYellow -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Parameter -ForegroundColor DarkCyan -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Type -ForegroundColor Blue -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Number -ForegroundColor Red -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Member -ForegroundColor DarkRed -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind None -ForegroundColor White -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Comment -ForegroundColor Black -BackgroundColor DarkGray

        Set-PSReadlineOption -EmphasisForegroundColor White -EmphasisBackgroundColor $BackgroundColor `
                             -ContinuationPromptForegroundColor DarkBlue -ContinuationPromptBackgroundColor $BackgroundColor -ContinuationPrompt (([char]183) + "  ")
    }

    Set-PSReadLineMyWay
    Set-PSReadlineKeyHandler -Key "Ctrl+Shift+R" -Function ForwardSearchHistory
    Set-PSReadlineKeyHandler -Key "Ctrl+R" -Function ReverseSearchHistory

    Set-PSReadlineKeyHandler Ctrl+M SetMark
    Set-PSReadlineKeyHandler Ctrl+Shift+M ExchangePointAndMark

    Set-PSReadlineKeyHandler Ctrl+K KillLine
    Set-PSReadlineKeyHandler Ctrl+I Yank
    Trace-Message "PSReadLine fixed"
} else {
    Remove-Module PSReadLine -ErrorAction SilentlyContinue
    Trace-Message "PSReadLine skipped!"
}

<#
   Superfluous but fun quotes. 
   By default we look for these in $ProfileDir\Data\quotes.txt
#>
$Script:QuoteDir = Join-Path (Split-Path $Profile -parent) "Data"

if(Test-Path $Script:QuoteDir) {
    # Only export $QuoteDir if it refers to a folder that actually exists
    Set-Variable QuoteDir (Resolve-Path $QuoteDir) -Scope Global -Option AllScope -Description "Personal PATH Variable"

    function Get-Quote {
        param(
            $Path = "${QuoteDir}\quotes.txt",
            [int]$Count=1
        )
        if(!(Test-Path $Path) ) {
            $Path = Join-Path ${QuoteDir} $Path
            if(!(Test-Path $Path) ) {
                $Path = $Path + ".txt"
            }
        }
        Get-Content $Path | Where-Object { $_ } | Get-Random -Count $Count
    }
    
    ## Get a random quote, and print it in yellow :D
    if( Test-Path "${QuoteDir}\attributed quotes.txt" ) {
        Get-Quote | Write-Host -Foreground Yellow
    }
    
    Set-Alias gq Get-Quote
    Trace-Message "Random Quotes Loaded" 
}

## Fix em-dash screwing up our commands...
$ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = {
    param( $CommandName, $CommandLookupEventArgs )
    if($CommandName.Contains([char]8211)) {
        $CommandLookupEventArgs.Command = Get-Command ( $CommandName -replace ([char]8211), ([char]45) ) -ErrorAction Ignore
    }
}

<#
 Write a quick banner and a random quote for fun
#>
if (-not $SHIFTED) {
    Clear-Host
}
Write-SessionBanner
Write-Host
try {Get-Quote} catch {}

<# 
 Clean up variables created in this profile that we don't wan't littering a cleanly started profile.
#>
Remove-Variable folders -ErrorAction SilentlyContinue
Remove-Variable SHIFTED -ErrorAction SilentlyContinue
Remove-Variable PersistentHistoryCount -ErrorAction SilentlyContinue

Trace-Message "Profile Finished!" -KillTimer

## And finally, relax the code signing restriction so we can actually get work done
Set-ExecutionPolicy RemoteSigned Process

