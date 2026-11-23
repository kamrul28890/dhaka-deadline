$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$projectRoot = Split-Path -Parent $PSScriptRoot
$buildRoot = Join-Path $projectRoot 'build\v2.0'
$enginePath = Join-Path $projectRoot '.tools\godot\Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $enginePath)) { throw 'Run python tools/setup_runtime.py first.' }
New-Item -ItemType Directory -Force -Path $buildRoot | Out-Null
& $enginePath --headless --path $projectRoot --editor --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
& $enginePath --headless --path $projectRoot --export-release 'Windows Desktop' (Join-Path $buildRoot 'DhakaDeadline.exe')
if ($LASTEXITCODE -ne 0) { throw 'Windows export failed.' }
Copy-Item -LiteralPath (Join-Path $projectRoot 'THIRD_PARTY_NOTICES.md') -Destination $buildRoot
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs\PLAYING.md') -Destination (Join-Path $buildRoot 'README.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets\fonts\OFL.txt') -Destination (Join-Path $buildRoot 'OFL.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets\manifest.json') -Destination (Join-Path $buildRoot 'asset-manifest.json')
foreach ($notice in @('Godot-LICENSE.txt', 'Godot-COPYRIGHT.txt')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot ('assets\licenses\' + $notice)) -Destination (Join-Path $buildRoot $notice)
}
$buildFiles = Get-ChildItem -LiteralPath $buildRoot -File | Where-Object { $_.Extension -ne '.zip' }
Compress-Archive -LiteralPath $buildFiles.FullName -DestinationPath (Join-Path $buildRoot 'DhakaDeadline-Windows.zip') -Force
Write-Output "Built $buildRoot\DhakaDeadline.exe and $buildRoot\DhakaDeadline-Windows.zip"
