param([string]$MSBuild = 'C:/Program Files (x86)/MSBuild/14.0/Bin/MSBuild.exe')
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'Restore-Toolkit.ps1')
& $MSBuild (Join-Path $PSScriptRoot 'ToggleSwitchReference.csproj') /t:Rebuild /p:Configuration=Release /nologo /verbosity:minimal
if ($LASTEXITCODE -ne 0) { throw 'Native ToggleSwitch reference build failed.' }
