#!/usr/bin/env pwsh

param([string]$path)

function format-ps1 {
    Param([string]$path)
    
    $fullPath = (Resolve-Path -Path $path -ErrorAction Stop).Path
    
    if (Test-Path $fullPath -PathType Leaf) {
        Import-Module PSScriptAnalyzer -ErrorAction SilentlyContinue
        $output = Invoke-Formatter -ScriptDefinition ([IO.File]::ReadAllText($fullPath))

        [Console]::Write($output)
        Set-Content $path $output -NoNewline;
    }
}

format-ps1 $path
