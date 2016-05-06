# if you're running "elevated" we want to know that:
$global:PSProcessElevated = ([System.Environment]::OSVersion.Version.Major -gt 5) -and ( # Vista and ...
                                    new-object Security.Principal.WindowsPrincipal (
                                    [Security.Principal.WindowsIdentity]::GetCurrent()) # current user is admin
                                ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$OFS = ';'

function LoadSpecialFolders {
    $Script:SpecialFolders = @{}

    foreach($name in [System.Environment+SpecialFolder].GetFields("Public,Static") | Sort-Object Name) { 
        $Script:SpecialFolders.($name.Name) = [int][System.Environment+SpecialFolder]$name.Name

        if($Name.Name.StartsWith("My")) {
            $Script:SpecialFolders.($name.Name.Substring(2)) = [int][System.Environment+SpecialFolder]$name.Name
        }
    }
    $Script:SpecialFolders.CommonModules = Join-Path $Env:ProgramFiles "WindowsPowerShell\Modules"
    $Script:SpecialFolders.CommonProfile = (Split-Path $Profile.AllUsersAllHosts)
    $Script:SpecialFolders.Modules = Join-Path (Split-Path $Profile.CurrentUserAllHosts) "Modules"
    $Script:SpecialFolders.Profile = (Split-Path $Profile.CurrentUserAllHosts)
    $Script:SpecialFolders.PSHome = $PSHome
    $Script:SpecialFolders.SystemModules = Join-Path (Split-Path $Profile.AllUsersAllHosts) "Modules"
}

$Script:SpecialFolders = [Ordered]@{}

function Get-SpecialFolder {
  #.Synopsis
  #   Gets the current value for a well known special folder
  [CmdletBinding()]
  param(
    # The name of the Path you want to fetch (supports wildcards).
    #  From the list: AdminTools, ApplicationData, CDBurning, CommonAdminTools, CommonApplicationData, CommonDesktopDirectory, CommonDocuments, CommonMusic, CommonOemLinks, CommonPictures, CommonProgramFiles, CommonProgramFilesX86, CommonPrograms, CommonStartMenu, CommonStartup, CommonTemplates, CommonVideos, Cookies, Desktop, DesktopDirectory, Favorites, Fonts, History, InternetCache, LocalApplicationData, LocalizedResources, MyComputer, MyDocuments, MyMusic, MyPictures, MyVideos, NetworkShortcuts, Personal, PrinterShortcuts, ProgramFiles, ProgramFilesX86, Programs, PSHome, Recent, Resources, SendTo, StartMenu, Startup, System, SystemX86, Templates, UserProfile, Windows
    [ValidateScript({
        $Name = $_
        if(!$Script:SpecialFolders.Count -gt 0) { LoadSpecialFolders }
        if($Script:SpecialFolders.Keys -like $Name){
            return $true
        } else {
            throw "Cannot convert Path, with value: `"$Name`", to type `"System.Environment+SpecialFolder`": Error: `"The identifier name $Name is not one of $($Script:SpecialFolders.Keys -join ', ')"
        }
    })]
    [String]$Path = "*",

    # If not set, returns a hashtable of folder names to paths
    [Switch]$Value
  )

  $Names = $Script:SpecialFolders.Keys -like $Path
  if(!$Value) {
    $return = @{}
  }

  foreach($name in $Names) {
    $result = $(
      $id = $Script:SpecialFolders.$name
      if($Id -is [string]) {
        $Id
      } else {
        ($Script:SpecialFolders.$name = [Environment]::GetFolderPath([int]$Id))
      }
    )

    if($result) {
      if($Value) {
        Write-Output $result
      } else {
        $return.$name = $result
      }
    }
  }
  if(!$Value) {
    Write-Output $return
  }
}

function Set-EnvironmentVariable {
    #.Synopsis
    # Set an environment variable at the highest scope possible
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [String]$Name,

        [Parameter(Position=1)]
        [String]$Value,

        [System.EnvironmentVariableTarget]
        $Scope="Machine",

        [Switch]$FailFast
    )

    Set-Content "ENV:$Name" $Value
    $Success = $False
    do {
        try {
            [System.Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
            Write-Verbose "Set $Scope environment variable $Name = $Value"
            $Success = $True
        }
        catch [System.Security.SecurityException] 
        {
            if($FailFast) {
                $PSCmdlet.ThrowTerminatingError( (New-Object System.Management.Automation.ErrorRecord (
                    New-Object AccessViolationException "Can't set environment variable in $Scope scope"
                ), "FailFast:$Scope", "PermissionDenied", $Scope) )
            } else {
                Write-Warning "Cannot set environment variables in the $Scope scope"
            }
            $Scope = [int]$Scope - 1
        }
    } while(!$Success -and $Scope -gt "Process")
}

function Add-Path {
    #.Synopsis
    #  Add a folder to a path environment variable
    #.Description
    #  Gets the existing content of the path variable, splits it with the PathSeparator,
    #  adds the specified paths, and then joins them and re-sets the EnvironmentVariable
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$True)]
        [String]$Name,

        [Parameter(Position=1)]
        [String[]]$Append = @(),

        [String[]]$Prepend = @(),

        [System.EnvironmentVariableTarget]
        $Scope="User",

        [Char]
        $Separator = [System.IO.Path]::PathSeparator
    )

    # Make the new thing as an array so we don't get duplicates
    $Path = @($Prepend -split "$Separator" | %{ $_.TrimEnd("\/") } | ?{ $_ })
    $Path += $OldPath = @([Environment]::GetEnvironmentVariable($Name, $Scope) -split "$Separator" | %{ $_.TrimEnd("\/") }| ?{ $_ })
    $Path += @($Append -split "$Separator" | %{ $_.TrimEnd("\/") }| ?{ $_ })

    # Dedup path
    # If the path actually exists, use the actual case of the folder
    $Path = $(foreach($Folder in $Path) {
                if(Test-Path $Folder) {
                    Get-Item ($Folder -replace '(?<!:)(\\|/)', '*$1') | Where FullName -ieq $Folder | % FullName
                } else { $Folder }
            } ) | Select -Unique

    # Turn them back into strings
    $Path = $Path -join "$Separator"
    $OldPath = $OldPath -join "$Separator"

    # Path environment variables are kind-of a pain:
    # The current value in the process scope is a combination of machine and user, with changes
    # We need to fix the CURRENT path instead of just setting it
    $OldEnvPath = @($(Get-Content "ENV:$Name") -split "$Separator" | %{ $_.TrimEnd("\/") }) -join "$Separator"
    if("$OldPath".Trim().Length -gt 0) {
        Write-Verbose "Old $Name Path: $OldEnvPath"
        $OldEnvPath = $OldEnvPath -Replace ([regex]::escape($OldPath)), $Path
        Write-Verbose "New $Name Path: $OldEnvPath"
    } else {
        if($Append) {
            $OldEnvPath = $OldEnvPath + "$Separator" + $Path
        } else {
            $OldEnvPath = $Path + "$Separator" + $OldEnvPath
        }
    }

    Set-EnvironmentVariable $Name $($Path -join "$Separator") -Scope $Scope -FailFast
    if($?) {
        # Set the path back to the normalized value
        Set-Content "ENV:$Name" $OldEnvPath
    }
}

function Select-UniquePath {
    [CmdletBinding()]
    param(
        # If non-full, split path by the delimiter. Defaults to ';' so you can use this on $Env:Path
        [AllowNull()]
        [string]$Delimiter=';',

        # Paths to folders
        [Parameter(Position=1,Mandatory=$true,ValueFromRemainingArguments=$true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Path
    )
    begin {
        $Output = [string[]]@()
    }
    process {
        <#
            # This was the original code and it seems to 'eat' paths on me for some reason so I replaced it
            $Output += $(foreach($folderPath in $Path) {
            if($Delimiter) { 
                $folderPath = $folderPath -split $Delimiter
            }
            foreach($folder in @($folderPath)) {
                $folder = $folder.TrimEnd('\/')
                if($folderPath = $folder -replace '(?<!:)(\\|/)', '*$1') {
                    Get-Item $folderPath -ErrorAction Ignore | Where FullName -ieq $folder
                }
            }
        })#>
        $Output = @()
        foreach($folderPath in $Path) {
            if ($Delimiter) { 
                $folderPath = $folderPath -split $Delimiter
            }
            $folderPath = $folderPath | Foreach {$_.TrimEnd('\/')} | Sort-Object | Select-Object -Unique
            $folderPath | Foreach {
                if (Test-Path $_) {
                    $Output += Get-Item $_ 
                    Write-Verbose "Unique path added:: $($_)" 
                }
                else {
                    Write-Verbose "Path excluded because it doesn't exist: $($_)"
                }
            }
        }
    }
    end {
        if($Delimiter) {
            ($Output | Select -Expand FullName -Unique) -join $Delimiter
        } else {
            $Output | Select -Expand FullName -Unique
        }
    }
}

function Trace-Message {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$Message,

        [switch]$AsWarning,

        [switch]$ResetTimer,

        [switch]$KillTimer,

        [Diagnostics.Stopwatch]$Stopwatch
    )
    begin {
        if($Stopwatch) {
            $Script:TraceTimer = $Stopwatch    
            $Script:TraceTimer.Start()
        }
        if(-not $Script:TraceTimer) {
            $Script:TraceTimer = New-Object System.Diagnostics.Stopwatch
            $Script:TraceTimer.Start()
        }

        if($ResetTimer) 
        {
            $Script:TraceTimer.Restart()
        }
    }

    process {
        $Message = "$Message - at {0} Line {1} | {2}" -f (Split-Path $MyInvocation.ScriptName -Leaf), $MyInvocation.ScriptLineNumber, $TraceTimer.Elapsed

        if($AsWarning) {
            Write-Warning $Message
        } else {
            Write-Verbose $Message
        }
    }

    end {
        if($KillTimer) {
            $Script:TraceTimer.Stop()
            $Script:TraceTimer = $null
        }
    }
}

function Set-AliasToFirst {
    param(
        [string[]]$Alias,
        [string[]]$Path,
        [string]$Description = "the app in $($Path[0])...",
        [switch]$Force,
        [switch]$Passthru
    )
    if($App = Resolve-Path $Path -EA Ignore | Sort LastWriteTime -Desc | Select-Object -First 1 -Expand Path) {
        foreach($a in $Alias) {
            Set-Alias $a $App -Scope Global -Option Constant, ReadOnly, AllScope -Description $Description -Force:$Force
        }
        if($Passthru) {
            Split-Path $App
        }
    } else {
        Write-Warning "Could not find $Description"
    }
}

function Write-SessionBanner {
    try {
        $IPAddress = @(Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {$_.DefaultIpGateway})[0].IPAddress[0]
    }
    catch {
        $IPAddress = 'Offline'
    }
    try {
        $IPGateway=@(Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {$_.DefaultIpGateway})[0].DefaultIPGateway[0]
    }
    catch {
        $IPGateway = 'Offline'
    }
    $PSExecPolicy=Get-ExecutionPolicy
    $PSVersion=$PSVersionTable.PSVersion.Major

    Write-Host " -----------------------------------------------------------------------------------------------" -ForegroundColor Green
    Write-Host "�`tComputerName:`t`t" -nonewline -ForegroundColor Green;Write-Host $($env:COMPUTERNAME)"`t`t" -nonewline -ForegroundColor Cyan;Write-Host "UserName:`t" -nonewline -ForegroundColor Green;Write-Host $env:UserDomain\$env:UserName"`t`t" -nonewline -ForegroundColor Cyan;Write-Host "�" -ForegroundColor Green
    Write-Host "�`tLogon Server:`t`t" -nonewline -ForegroundColor Green;Write-Host $($env:LOGONSERVER)"`t`t" -nonewline -ForegroundColor Cyan;Write-Host "IP Address:`t" -nonewline -ForegroundColor Green;Write-Host $IPAddress"`t`t" -nonewline -ForegroundColor Cyan;Write-Host "�" -ForegroundColor Green
    Write-Host "�`tPS Execution Policy:`t" -nonewline -ForegroundColor Green;Write-Host $($PSExecPolicy)"`t`t" -nonewline -ForegroundColor Cyan;Write-Host "PS Version:`t" -nonewline -ForegroundColor Green;Write-Host $PSVersion"`t`t`t" -nonewline -ForegroundColor Cyan;Write-Host "�" -ForegroundColor Green
    Write-Host "�`tUptime:`t`t`t" -nonewline -ForegroundColor Green;Write-Host $(Get-Uptime)"`t`t`t`t`t" -nonewline -ForegroundColor Cyan;Write-Host "�" -ForegroundColor Green
    Write-Host " -----------------------------------------------------------------------------------------------`n" -ForegroundColor Green
}

function Reset-Module ($ModuleName) {
    rmo $ModuleName; ipmo $ModuleName -force -pass | ft Name, Version, Path -AutoSize
}

function Get-Uptime {
    $os = Get-WmiObject win32_operatingsystem
    $uptime = (Get-Date) - ($os.ConvertToDateTime($os.lastbootuptime))
    $Display = "" + $Uptime.Days + " days / " + $Uptime.Hours + " hours / " + $Uptime.Minutes + " minutes"
    Write-Output $Display
}

function qq {
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$q
    )
    
    $q
}

function Set-Prompt {
    <#
    .Synopsis
    Sets my favorite prompt function
    
    .Notes
    I put the id in my prompt because it's very, very useful.
    
    Invoke-History and my Expand-Alias and Get-PerformanceHistory all take command history IDs
    Also, you can tab-complete with "#<id>[Tab]" so .
    For example, the following commands:
    r 4
    ## r is an alias for invoke-history, so this reruns your 4th command
    
    #6[Tab]
    ## will tab-complete whatever you typed in your 6th command (now you can edit it)
    
    Expand-Alias -History 6,8,10 > MyScript.ps1
    ## generates a script from those history items
    
    GPH -id 6, 8
    ## compares the performance of those two commands ...
    
    Ganked from Joel Bennett at http://poshcode.org/4705
    #>
    [CmdletBinding(DefaultParameterSetName="Default")]
    param(
       # Controls how much history we keep in the command log between sessions
       [Int]$PersistentHistoryCount = 30,
       
       # If set, we use a pasteable prompt with <# #> around the prompt info
       [Parameter(ParameterSetName="Pasteable")]
       [Alias("copy","demo")][Switch]$Pasteable, 

       # If set, use a simple, clean prompt (otherwise use a fancy multi-line prompt)
       [Parameter(ParameterSetName="Clean")]
       [Switch]$Clean, 

       # Maximum history count
       [Int]$MaximumHistoryCount = 2048,
       # The main prompt foreground color
       [ConsoleColor]$Foreground = "Yellow",
       # The ERROR prompt foreground color
       [ConsoleColor]$ErrorForeground = "DarkRed",
       # The prompt background (should probably match your console background)
       [ConsoleColor]$Background = "Black"
    )
    end {
       # Regression bug?
       [ConsoleColor]$global:PromptForeground = $Foreground 
       [ConsoleColor]$global:ErrorForeground = $ErrorForeground
       [ConsoleColor]$global:PromptBackground = $Background
       $global:MaximumHistoryCount = $MaximumHistoryCount
       $global:PersistentHistoryCount = $PersistentHistoryCount

       # Some stuff goes OUTSIDE the prompt function because it doesn't need re-evaluation

       # I set the title in my prompt every time, because I want the current PATH location there,
       # rather than in my prompt where it takes up too much space.

       # But I want other stuff too. I  calculate an initial prefix for the window title
       # The title will show the PowerShell version, user, current path, and whether it's elevated or not
       # E.g.:"PoSh3 Jaykul@HuddledMasses (ADMIN) - C:\Your\Path\Here (FileSystem)" 
       if(!$global:WindowTitlePrefix) {
          $global:WindowTitlePrefix = "PoSh$($PSVersionTable.PSVersion.Major) ${Env:UserName}@${Env:UserDomain}"
          
          # if you're running "elevated" we want to show that:
          $PSProcessElevated = ([System.Environment]::OSVersion.Version.Major -gt 5) -and ( # Vista and ...
                                     new-object Security.Principal.WindowsPrincipal (
                                     [Security.Principal.WindowsIdentity]::GetCurrent()) # current user is admin
                                  ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
          
          if($PSProcessElevated) {
             $global:WindowTitlePrefix += " (ADMIN)"
          }
       }

       ## Global first-run (profile or first prompt)
       if($MyInvocation.HistoryId -eq 1) {
            if ($global:profiledir -eq $null) {
                $ProfileDir = Split-Path $Profile.CurrentUserAllHosts
            }
          ## Import my history
          if (Test-Path $ProfileDir\.poshhistory) {
            Import-CSV $ProfileDir\.poshhistory | Add-History
          }
       }

       if(Get-Module Posh-Git){
          Import-Module Posh-Git
       }

       if($Pasteable) {
          # The pasteable prompt starts with "<#PS " and ends with " #>"
          #   so that you can copy-paste with the prompt and it will still run
          function global:prompt {
             # FIRST, make a note if there was an error in the previous command
             $err = !$?
             Write-host "<#PS " -NoNewLine -fore gray

             # Make sure Windows and .Net know where we are (they can only handle the FileSystem)
             [Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath
             
             try {
                # Also, put the path in the title ... (don't restrict this to the FileSystem)
                $Host.UI.RawUI.WindowTitle = "{0} - {1} ({2})" -f $global:WindowTitlePrefix,$pwd.Path,$pwd.Provider.Name
             } catch {}
             
             # Determine what nesting level we are at (if any)
             $Nesting = "$([char]0xB7)" * $NestedPromptLevel

             # Generate PUSHD(push-location) Stack level string
             $Stack = "+" * (Get-Location -Stack).count
             
             # I used to use Export-CliXml, but Export-CSV is a lot faster
             $null = Get-History -Count $PersistentHistoryCount | Export-CSV $ProfileDir\.poshhistory
             # Output prompt string
             # If there's an error, set the prompt foreground to the error color...
             if($err) { $fg = $global:ErrorForeground } else { $fg = $global:PromptForeground }
             # Notice: no angle brackets, makes it easy to paste my buffer to the web
             Write-Host "[${Nesting}$($myinvocation.historyID)${Stack}]" -NoNewLine -Foreground $fg
             Write-host " #>" -NoNewLine -fore gray
             # Hack PowerShell ISE CTP2 (requires 4 characters of output)
             if($Host.Name -match "ISE" -and $PSVersionTable.BuildVersion -eq "6.2.8158.0") {
                return "$("$([char]8288)"*3) " 
             } else {
                return " "
             }
          }
       } elseif($Clean) {
          function global:prompt {
             # FIRST, make a note if there was an error in the previous command
             $err = !$?

             # Make sure Windows and .Net know where we are (they can only handle the FileSystem)
             [Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath
             
             try {
                # Also, put the path in the title ... (don't restrict this to the FileSystem)
                $Host.UI.RawUI.WindowTitle = "{0} - {1} ({2})" -f $global:WindowTitlePrefix, $pwd.Path,  $pwd.Provider.Name
             } catch {}
             
             # Determine what nesting level we are at (if any)
             $Nesting = "$([char]0xB7)" * $NestedPromptLevel

             # Generate PUSHD(push-location) Stack level string
             $Stack = "+" * (Get-Location -Stack).count
             
             # I used to use Export-CliXml, but Export-CSV is a lot faster
             $null = Get-History -Count $PersistentHistoryCount | Export-CSV $ProfileDir\.poshhistory

             # Output prompt string
             # If there's an error, set the prompt foreground to "Red", otherwise, "Yellow"
             if($err) { $fg = $global:ErrorForeground } else { $fg = $global:PromptForeground }
             # Notice: no angle brackets, makes it easy to paste my buffer to the web
             Write-Host "[${Nesting}$($myinvocation.historyID)${Stack}]:" -NoNewLine -Fore $fg
             # Hack PowerShell ISE CTP2 (requires 4 characters of output)
             if($Host.Name -match "ISE" -and $PSVersionTable.BuildVersion -eq "6.2.8158.0") {
                return "$("$([char]8288)"*3) "
             } else {
                return " "
             }
          }
       } else {
          function global:prompt {
             # FIRST, make a note if there was an error in the previous command
             $err = !$?

             # Make sure Windows and .Net know where we are (they can only handle the FileSystem)
             [Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath
             
             try {
                # Also, put the path in the title ... (don't restrict this to the FileSystem)
                $Host.UI.RawUI.WindowTitle = "{0} - {1} ({2})" -f $global:WindowTitlePrefix,$pwd.Path,$pwd.Provider.Name
             } catch {}
             
             # Determine what nesting level we are at (if any)
             $Nesting = "$([char]0xB7)" * $NestedPromptLevel

             # Generate PUSHD(push-location) Stack level string
             $Stack = "+" * (Get-Location -Stack).count
             
             # I used to use Export-CliXml, but Export-CSV is a lot faster
             $null = Get-History -Count $PersistentHistoryCount | Export-CSV $ProfileDir\.poshhistory

             # Output prompt string
             # If there's an error, set the prompt foreground to "Red", otherwise, "Yellow"
             if($err) { $fg = $global:ErrorForeground } else { $fg = $global:PromptForeground }
             # Notice: no angle brackets, makes it easy to paste my buffer to the web
             Write-Host '&#9556;' -NoNewLine -Foreground $global:PromptBackground
             Write-Host " $(if($Nesting){"$Nesting "})#$($MyInvocation.HistoryID)${Stack} " -Background $global:PromptBackground -Foreground $fg -NoNewLine
             if(Get-Module Posh-Git) {
                $LEC = $LASTEXITCODE
                Set-GitPromptSettings -DefaultForegroundColor $fg -DefaultBackgroundColor $global:PromptBackground -BeforeForegroundColor Black -DelimForegroundColor Black -AfterForegroundColor Black -BranchBehindAndAheadForegroundColor Black
                $path = $pwd -replace $([Regex]::Escape((Convert-Path "~"))),"~"
                Write-Host $path -Background $global:PromptBackground -Foreground $fg -NoNewLine
                Write-VcsStatus
                $global:LASTEXITCODE = $LEC
             }
             Write-Host ' '
             Write-Host '&#9562;&#9552;&#9552;&#9552;&#9557;' -Foreground $global:PromptBackground -NoNewLine
             # Hack PowerShell ISE CTP2 (requires 4 characters of output)
             if($Host.Name -match "ISE" -and $PSVersionTable.BuildVersion -eq "6.2.8158.0") {
                return "$("$([char]8288)"*3) "
             } else {
                return " "
             }
          }
       }
    }
}

