# Simple script to create the necessary json file to allow vscode to debug a script file
param ([string]$ScriptName)

$ScriptName = $ScriptName -replace './','' -replace '.\',''
$Template = @'
{
    "version": "0.2.0",
    "configurations": [{
        "name": "PowerShell",
        "type": "PowerShell",
        "request": "launch",
        "program": "${workspaceRoot}/{{ScriptName}}"
    }]
}

'@ -replace "{{ScriptName}}", $ScriptName

if (-not (test-path '.\.vscode')) {
    New-Item -Name '.vscode' -ItemType:Directory
}

$Template | Out-File -FilePath '.\.vscode\launch.json' -Force -Encoding utf8

Write-Host 'json file created, remember to open the current folder in vscode. Use f5 to start debugging, use ctrl+shift+D to see the debugger panel.'