param([string]$MSBuild = 'C:/Program Files (x86)/MSBuild/14.0/Bin/MSBuild.exe', [switch]$NoState)
$ErrorActionPreference = 'Stop'
& $MSBuild (Join-Path $PSScriptRoot 'PanoramaReference.csproj') /t:Rebuild /p:Configuration=Release "/p:EvidenceTelemetry=$(!$NoState)" /nologo /verbosity:minimal
if ($LASTEXITCODE -ne 0) { throw 'Native Panorama reference build failed.' }
