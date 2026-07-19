$ErrorActionPreference = 'Stop'

$frontendRoot = Split-Path $PSScriptRoot -Parent
$unifiedRoot = Join-Path $frontendRoot 'damos_mart_unified'
$packagesRoot = Join-Path $unifiedRoot 'packages'

$variants = @(
  @{ Folder = 'damos_mart_conscientiousness'; Package = 'variant_conscientiousness' },
  @{ Folder = 'damos_mart_influence'; Package = 'variant_influence' },
  @{ Folder = 'damos_mart_dominance'; Package = 'variant_dominance' },
  @{ Folder = 'damos_mart_steadiness'; Package = 'variant_steadiness' }
)

$exclude = @('.dart_tool', 'build', '.idea', 'ephemeral', '.cxx', '.plugin_symlinks', 'android.zip')

function Invoke-RoboCopy {
  param([string]$Source, [string]$Destination)
  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  $xd = $exclude | ForEach-Object { '/XD', $_ }
  robocopy $Source $Destination /E /NFL /NDL /NJH /NJS @xd | Out-Null
  if ($LASTEXITCODE -gt 7) { throw "robocopy failed ($LASTEXITCODE): $Source" }
}

function New-VariantPackage {
  param(
    [string]$SourceRoot,
    [string]$DestRoot,
    [string]$OldPackageName,
    [string]$NewPackageName
  )

  if (Test-Path $DestRoot) {
    Remove-Item $DestRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
  New-Item -ItemType Directory -Force -Path $DestRoot | Out-Null

  Invoke-RoboCopy (Join-Path $SourceRoot 'lib') (Join-Path $DestRoot 'lib')
  if (Test-Path (Join-Path $SourceRoot 'assets')) {
    Invoke-RoboCopy (Join-Path $SourceRoot 'assets') (Join-Path $DestRoot 'assets')
  }

  $pubspecSrc = Join-Path $SourceRoot 'pubspec.yaml'
  $pubspecDest = Join-Path $DestRoot 'pubspec.yaml'
  $yaml = Get-Content $pubspecSrc -Raw -Encoding UTF8
  $yaml = $yaml -replace "(?m)^name:\s*${OldPackageName}\s*$", "name: $NewPackageName"
  if ($yaml -notmatch '(?m)^publish_to:') {
    $yaml = $yaml -replace '(?m)^(name:\s*.+)$', "`$1`npublish_to: none"
  }
  Set-Content -Path $pubspecDest -Value $yaml -Encoding UTF8 -NoNewline

  Get-ChildItem (Join-Path $DestRoot 'lib') -Recurse -Filter '*.dart' | ForEach-Object {
    $content = Get-Content $_.FullName -Raw -Encoding UTF8
    $updated = $content.Replace("package:$OldPackageName/", "package:$NewPackageName/")
    if ($updated -ne $content) {
      Set-Content -Path $_.FullName -Value $updated -Encoding UTF8 -NoNewline
    }
  }

  @"
import 'package:flutter/widgets.dart';
import 'app.dart';

class VariantEntry {
  static Widget app() => const DamosMartApp();
}
"@ | Set-Content -Path (Join-Path $DestRoot 'lib\variant_entry.dart') -Encoding UTF8
}

Write-Host '=== Host shell (platform files from conscientiousness) ==='
$base = Join-Path $frontendRoot 'damos_mart_conscientiousness'
New-Item -ItemType Directory -Force -Path $unifiedRoot | Out-Null

foreach ($dir in @('android', 'ios', 'web', 'linux', 'macos', 'windows', 'assets', 'test')) {
  $src = Join-Path $base $dir
  if (Test-Path $src) {
    Invoke-RoboCopy $src (Join-Path $unifiedRoot $dir)
  }
}

Copy-Item (Join-Path $base 'analysis_options.yaml') (Join-Path $unifiedRoot 'analysis_options.yaml') -Force
Copy-Item (Join-Path $base '.metadata') (Join-Path $unifiedRoot '.metadata') -Force -ErrorAction SilentlyContinue

# Fix Android package id + MainActivity for unified host
$androidGradle = Join-Path $unifiedRoot 'android\app\build.gradle.kts'
if (Test-Path $androidGradle) {
  $gradle = Get-Content $androidGradle -Raw -Encoding UTF8
  $gradle = $gradle.Replace('com.example.damos_mart_conscientiousness', 'com.example.damos_mart_unified')
  Set-Content -Path $androidGradle -Value $gradle -Encoding UTF8 -NoNewline
}
$oldKotlinDir = Join-Path $unifiedRoot 'android\app\src\main\kotlin\com\example\damos_mart_conscientiousness'
$newKotlinDir = Join-Path $unifiedRoot 'android\app\src\main\kotlin\com\example\damos_mart_unified'
if (Test-Path $oldKotlinDir) {
  New-Item -ItemType Directory -Force -Path $newKotlinDir | Out-Null
  $mainActivity = Join-Path $oldKotlinDir 'MainActivity.kt'
  if (Test-Path $mainActivity) {
    $kt = Get-Content $mainActivity -Raw -Encoding UTF8
    $kt = $kt.Replace('package com.example.damos_mart_conscientiousness', 'package com.example.damos_mart_unified')
    Set-Content -Path (Join-Path $newKotlinDir 'MainActivity.kt') -Value $kt -Encoding UTF8 -NoNewline
    Remove-Item $oldKotlinDir -Recurse -Force
  }
}

Write-Host '=== Variant packages (lib + assets only) ==='
New-Item -ItemType Directory -Force -Path $packagesRoot | Out-Null
foreach ($variant in $variants) {
  $source = Join-Path $frontendRoot $variant.Folder
  $dest = Join-Path $packagesRoot $variant.Package
  Write-Host $variant.Package
  New-VariantPackage -SourceRoot $source -DestRoot $dest `
    -OldPackageName $variant.Folder -NewPackageName $variant.Package
}

Write-Host '=== disc_core ==='
$discCore = Join-Path $packagesRoot 'disc_core'
if (Test-Path $discCore) { Remove-Item $discCore -Recurse -Force }
New-Item -ItemType Directory -Force -Path (Join-Path $discCore 'lib') | Out-Null
Copy-Item (Join-Path $base 'lib\core\disc\disc_variant.dart') (Join-Path $discCore 'lib\disc_variant.dart') -Force

@"
name: disc_core
description: Shared DISC selection for Damos Mart unified app.
version: 1.0.0
publish_to: none

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2
"@ | Set-Content -Path (Join-Path $discCore 'pubspec.yaml') -Encoding UTF8

Write-Host 'Done init_unified_app'
