##requires -version 2.0
## Get-PerformanceHistory.ps1
##############################################################################################################
## Lets you see the amount of time recent commands in your history have taken
## History:
## v2.53 - added back the Lines, Words, and Characters ....
## v2.52 - added regex-based iteration counting to calculate averages
## v2.51 - removed PsParser features to make it v1 compatible
## v2.5 - added "average" calculation if the first thing in your command line is a range: 1..x
## v2   - added measuring the scripts involved in the command, (uses Tokenizer)
##      - adds a ton of parsing to make the output pretty
##############################################################################################################
function Get-PerformanceHistory {
    param( [int]$count=1, [int[]]$id=@((Get-History -count 1| Select Id).Id) )

    ## Removed to make this v1 compatible
    ## $Parser = [System.Management.Automation.PsParser]
    function FormatTimeSpan($ts) {
       if($ts.Minutes) {
          if($ts.Hours) {
             if($ts.Days) {
                return "{0:##}d {1:00}:{2:00}:{3:00}.{4:00000}" -f $ts.Days, $ts.Hours, $ts.Minutes, $ts.Seconds, [int](100000 * ($ts.TotalSeconds - [Math]::Floor($ts.TotalSeconds)))
             }
             return "{0:##}:{1:00}:{2:00}.{3:00000}" -f $ts.Hours, $ts.Minutes, $ts.Seconds, [int](100000 * ($ts.TotalSeconds - [Math]::Floor($ts.TotalSeconds)))
          }
          return "{0:##}:{1:00}.{2:00000}" -f $ts.Minutes, $ts.Seconds, [int](100000 * ($ts.TotalSeconds - [Math]::Floor($ts.TotalSeconds)))
       }
       return "{0:#0}.{1:00000}" -f $ts.Seconds, [int](100000 * ($ts.TotalSeconds - [Math]::Floor($ts.TotalSeconds)))
    }

    # if there's only one id, then the count counts, otherwise we just use the ids
    # ... basically:    { 1..$count | % { $id += $id[-1]-1 }  }
    if($id.Count -eq 1) { $id = ($id[0])..($id[0]-($count-1)) } 

    # so we can call it with just the IDs
    Get-History -id $id | 
    ForEach {
       $msr = $null
       $cmd = $_
       # default formatting values
       $avg = 7; $len = 8; $count = 1
       
    ## Removed to make this v1 compatible
    ##   $tok = $Parser::Tokenize( $cmd.CommandLine, [ref]$null )
    ##   if( ($tok[0].Type -eq "Number") -and 
    ##       ($tok[0].Content -le 1) -and 
    ##       ($tok[2].Type -eq "Number") -and 
    ##       ($tok[1].Content -eq "..") )
    ##   {
    ##      $count = ([int]$tok[2].Content) - ([int]$tok[0].Content) + 1
    ##   }
    ##   
    ##   $com = @( $tok | where {$_.Type -eq "Command"} | 
    ##                     foreach { 
    ##                        $Local:ErrorActionPreference = "SilentlyContinue"
    ##                        get-command $_.Content 
    ##                        $Local:ErrorActionPreference = $Script:ErrorActionPreference
    ##                     } | 
    ##                     where { $_.CommandType -eq "ExternalScript" } |
    ##                     foreach { $_.Path } )
    ##                     
    ##   # If we actually got a script, measure it out
    ##   if($com.Count -gt 0){
    ##      $msr = Get-Content -path $com | Measure-Object -Line -Word -Char
    ##   } else {
          $msr = Measure-Object -in $cmd.CommandLine -Line -Word -Char
    ##   }

    ## V1 Averages:
    $min, $max = ([regex]"^\s*(?:(?<min>\d+)\.\.(?<max>\d+)\s+\||for\s*\([^=]+=\s*(?<min>\d+)\s*;[^;]+\-lt\s*(?<max>\d+)\s*;[^;)]+\)\s*{)").match( $cmd.CommandLine ).Groups[1,2] | % { [int]$_.Value }
    $count = $max - $min
    if($count -le 0 ) { $count = 1 }
       
       "" | Select @{n="Id";        e={$cmd.Id}},
                   @{n="Duration";  e={FormatTimeSpan ($cmd.EndExecutionTime - $cmd.StartExecutionTime)}},
                   @{n="Average";   e={FormatTimeSpan ([TimeSpan]::FromTicks( (($cmd.EndExecutionTime - $cmd.StartExecutionTime).Ticks / $count) ))}},
                   @{n="Lines";     e={$msr.Lines}},
                   @{n="Words";     e={$msr.Words}},
                   @{n="Chars";     e={$msr.Characters}},
                   @{n="Type";      e={if($com.Count -gt 0){"Script"}else{"Command"}}},
                   @{n="Commmand";  e={$cmd.CommandLine}}
    } | 
    # I have to figure out what the longest time string is to make it look its best
    Foreach { 
    $avg = [Math]::Max($avg,$_.Average.Length);
    $len = [Math]::Max($len,$_.Duration.Length);  
    $_ } | Sort Id |
    Format-Table @{l="Duration";e={"{0,$len}" -f $_.Duration}},@{l="Average";e={"{0,$avg}" -f $_.Average}},Lines,Words,Chars,Type,Commmand -auto
}
