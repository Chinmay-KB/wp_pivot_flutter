param([string]$MSBuild = 'C:/Program Files (x86)/MSBuild/14.0/Bin/MSBuild.exe')
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'Restore-Toolkit.ps1')
$iconSource = (Resolve-Path (Join-Path $PSScriptRoot '..\native_pivot\Assets\Icon.png')).Path
$iconDirectory = Join-Path $PSScriptRoot 'Assets'
$iconTarget = Join-Path $iconDirectory 'Icon.png'
New-Item -ItemType Directory -Force $iconDirectory | Out-Null
Copy-Item -LiteralPath $iconSource -Destination $iconTarget -Force
& $MSBuild (Join-Path $PSScriptRoot 'MicroControlsReference.csproj') /t:Rebuild /p:Configuration=Release /nologo /verbosity:minimal
if ($LASTEXITCODE -ne 0) { throw 'Native micro-controls reference build failed.' }
