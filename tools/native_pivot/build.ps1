param([string]$MSBuild = 'C:/Program Files (x86)/MSBuild/14.0/Bin/MSBuild.exe', [switch]$NoTrajectory)
$ErrorActionPreference = 'Stop'
& $MSBuild (Join-Path $PSScriptRoot 'PivotReference.csproj') /t:Rebuild /p:Configuration=Release "/p:EvidenceTelemetry=$(!$NoTrajectory)" /nologo /verbosity:minimal
if ($LASTEXITCODE -ne 0) { throw 'Native Pivot reference build failed.' }
