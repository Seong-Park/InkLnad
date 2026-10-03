$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$godotBinary = 'C:\Users\pjs93\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe'
Start-Process -FilePath $godotBinary -ArgumentList @('--editor', '--path', (Join-Path $projectRoot 'godot')) -WindowStyle Hidden
