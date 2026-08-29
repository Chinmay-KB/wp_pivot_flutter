param([string]$MSBuild = 'C:/Program Files (x86)/MSBuild/14.0/Bin/MSBuild.exe', [switch]$NoTrajectory)
$ErrorActionPreference = 'Stop'
$toggleRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\native_toggle_switch')).Path
& (Join-Path $toggleRoot 'Restore-Toolkit.ps1')
$toggleDll = Join-Path $toggleRoot 'packages\WPtoolkit.4.2013.8.16\lib\wp8\Microsoft.Phone.Controls.Toolkit.dll'
$localDir = Join-Path $PSScriptRoot 'packages\WPtoolkit.4.2013.8.16\lib\wp8'
$localDll = Join-Path $localDir 'Microsoft.Phone.Controls.Toolkit.dll'
if (-not (Test-Path $localDll)) {
    if (-not (Test-Path $toggleDll)) { throw 'Local WPtoolkit 4.2013.8.16 DLL is missing (toggle fixture packages).' }
    New-Item -ItemType Directory -Force $localDir | Out-Null
    Copy-Item -LiteralPath $toggleDll -Destination $localDll
}
& $MSBuild (Join-Path $PSScriptRoot 'ApplicationBarReference.csproj') /t:Rebuild /p:Configuration=Release /nologo /verbosity:minimal
if ($LASTEXITCODE -ne 0) { throw 'Native ApplicationBar reference build failed.' }
