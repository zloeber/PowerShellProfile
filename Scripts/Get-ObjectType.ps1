<#
.SYNOPSIS
Display the object type name
.DESCRIPTION
Display the object type name
.PARAMETER Obj
Object to get the typename of
.PARAMETER Tree
Show entire typename inheritence tree
.LINK
http://www.the-little-things.net   
.NOTES
Version
    1.0.0 06/14/2016
    - Initial release
Author : Zachary Loeber

.EXAMPLE
$a | Get-ObjectType.ps1

Description
-----------
Gets the type of object that $a is defined as.
#>
[CmdLetBinding()]
param(
    [Parameter(Mandatory = $True, ValueFromPipeline = $True, Position = 0, HelpMessage = 'An object to check.')]
    $Obj,
    [Parameter(Position = 1, HelpMessage = 'View as an inheritence tree.')]
    [switch]$Tree
)

Process {
    $Obj | Foreach {
        if ($Tree) {
            $depth = ''
            Foreach ($t in ($Obj).pstypenames) {
                Write-Output $depth$t
                $depth = '--'
            }
        }
        else {
            ($Obj).pstypenames[0]
        }
    }
}