param([string]$PackageRoot = (Join-Path $PSScriptRoot 'packages'))
$ErrorActionPreference = 'Stop'
$version = '4.2013.8.16'
$target = Join-Path $PackageRoot "WPtoolkit.$version"
$dll = Join-Path $target 'lib\wp8\Microsoft.Phone.Controls.Toolkit.dll'
if (Test-Path $dll) { return }
New-Item -ItemType Directory -Force $PackageRoot | Out-Null
$archive = Join-Path $PackageRoot "WPtoolkit.$version.nupkg"
Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/WPtoolkit/$version" -OutFile $archive
$actual = (Get-FileHash $archive -Algorithm SHA256).Hash
$expected = 'C54E3547A0C8943378DEB8E919C22D69618361AD6BEA6AD21C2D400F975CEFD1'
if ($actual -ne $expected) { throw "WPtoolkit SHA-256 mismatch: $actual" }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($archive, $target)
Remove-Item -LiteralPath $archive -Force
if (-not (Test-Path $dll)) { throw 'WPtoolkit restore did not contain the WP8 Toolkit DLL.' }

