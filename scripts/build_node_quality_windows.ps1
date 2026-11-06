param()

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$buildRoot = [IO.Path]::GetFullPath((Join-Path $root 'build'))
$stage = [IO.Path]::GetFullPath((Join-Path $buildRoot ('node-quality-release-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))))
if (-not $stage.StartsWith($buildRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Staging directory is outside the workspace build directory.'
}
if (Test-Path -LiteralPath $stage) { throw 'Choose a new staging directory.' }
New-Item -ItemType Directory -Path $stage | Out-Null

$names = 'BUILDKIT_OUTPUT_DIR', 'BUILDKIT_CONFIGURATION', 'CARGO_TARGET_DIR', 'FLUTTER_ROOT'
$saved = @{}
foreach ($name in $names) { $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
$published = @{}
foreach ($name in @('QuanClashCore.exe', 'QuanClashHelperService.exe')) {
    $path = Join-Path $root ('libclash/windows/' + $name)
    if (Test-Path -LiteralPath $path) { $published[$path] = (Get-FileHash -LiteralPath $path).Hash }
}
$rootManifest = Join-Path $root 'core_sha256.json'
if (Test-Path -LiteralPath $rootManifest) { $published[$rootManifest] = (Get-FileHash -LiteralPath $rootManifest).Hash }

Push-Location $root
try {
    $env:BUILDKIT_OUTPUT_DIR = Join-Path $stage 'artifacts'
    $env:BUILDKIT_CONFIGURATION = 'Release'
    $env:CARGO_TARGET_DIR = Join-Path $stage 'helper-target'
    $env:FLUTTER_ROOT = Split-Path (Split-Path (Get-Command flutter).Source -Parent) -Parent

    # Build only; never start/register/stop a service or launch the application.
    & (Join-Path $root 'plugins/setup/buildkit/run_build_tool.cmd') windows
    if ($LASTEXITCODE -ne 0) { throw 'Core/helper staging build failed.' }
    $manifest = Join-Path $env:BUILDKIT_OUTPUT_DIR 'windows/core_sha256.json'
    $expected = (Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json).CORE_SHA256
    if ($expected -notmatch '^[0-9a-f]{64}$') { throw 'Invalid staged core hash.' }

    & flutter build windows --release "--dart-define=CORE_SHA256=$expected"
    if ($LASTEXITCODE -ne 0) { throw 'Flutter release build failed.' }
    $sourceBundle = Join-Path $root 'build/windows/x64/runner/Release'
    $bundle = Join-Path $stage 'bundle'
    New-Item -ItemType Directory -Path $bundle | Out-Null
    foreach ($entry in Get-ChildItem -LiteralPath $sourceBundle) {
        Copy-Item -LiteralPath $entry.FullName -Destination $bundle -Recurse
    }
    $actual = (Get-FileHash -LiteralPath (Join-Path $bundle 'QuanClashCore.exe')).Hash.ToLowerInvariant()
    $built = (Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json).CORE_SHA256
    if ($actual -cne $expected -or $built -cne $expected) { throw 'Core changed during app compilation; refuse mismatched bundle.' }
    foreach ($name in @('QuanClashCore.exe', 'QuanClashHelperService.exe')) {
        if ((Get-FileHash -LiteralPath (Join-Path $bundle $name)).Hash -cne
            (Get-FileHash -LiteralPath (Join-Path $env:BUILDKIT_OUTPUT_DIR ('windows/' + $name))).Hash) {
            throw "Bundle does not contain the matching $name."
        }
    }
    foreach ($path in @((Join-Path $bundle 'data/app.so'), (Join-Path $bundle 'QuanClashHelperService.exe'))) {
        # Static artifact consistency only; do not start the privileged helper.
        if (-not [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($path)).Contains($expected)) {
            throw "Expected core hash is absent from $path."
        }
    }
    [ordered]@{
        schemaVersion = 1
        builtAt = (Get-Date).ToString('o')
        configuration = 'Release'
        embeddedCoreSha256 = $expected
        appSha256 = (Get-FileHash -LiteralPath (Join-Path $bundle 'QuanClash.exe')).Hash.ToLowerInvariant()
        appAotSha256 = (Get-FileHash -LiteralPath (Join-Path $bundle 'data/app.so')).Hash.ToLowerInvariant()
        rustIpcSha256 = (Get-FileHash -LiteralPath (Join-Path $bundle 'rust_api.dll')).Hash.ToLowerInvariant()
        helperSha256 = (Get-FileHash -LiteralPath (Join-Path $bundle 'QuanClashHelperService.exe')).Hash.ToLowerInvariant()
        bundle = $bundle
        runtimeVerified = $false
        remoteProvidersVerified = $false
    } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $stage 'delivery.json')
    Write-Output "Coordinated release bundle: $bundle"
    Write-Output "Core SHA256: $expected"
} finally {
    Pop-Location
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
    foreach ($path in $published.Keys) {
        if ((Get-FileHash -LiteralPath $path).Hash -cne $published[$path]) {
            throw "Existing release artifact changed: $path"
        }
    }
}
