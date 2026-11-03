<#
    Downloads the Visual C++ development packages (-VC.zip) of SDL3 and SDL3_ttf,
    verifies them against the SHA256 in sdl-versions.txt and extracts them under vendor/windows/.
    Finally sets up the environment for iyi's linker and for the running program:

      IYI_LIBRARY_PATH  SDL3.lib / SDL3_ttf.lib directories (iyi passes them to the
                        MSVC linker as /LIBPATH)
      PATH              SDL3.dll / SDL3_ttf.dll directories (while the program runs)

    To keep the environment in your session, dot-source it:

      . .\scripts\fetch-sdl.ps1

    On GitHub Actions it also writes to GITHUB_ENV / GITHUB_PATH so later steps see it.
#>
$ErrorActionPreference = 'Stop'
# Windows PowerShell 5.1 may start with an old TLS; GitHub requires 1.2.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$Root = Split-Path -Parent $PSScriptRoot
$Versions = @{}
foreach ($line in Get-Content (Join-Path $PSScriptRoot 'sdl-versions.txt')) {
    if ($line -match '^\s*([A-Z0-9_]+)=(\S+)\s*$') { $Versions[$Matches[1]] = $Matches[2] }
}

$Download = Join-Path $Root 'vendor\dl'
$Windows = Join-Path $Root 'vendor\windows'
New-Item -ItemType Directory -Force -Path $Download, $Windows | Out-Null

$LibDirs = @()
foreach ($pkg in @(
        @{ Repo = 'SDL'; Name = 'SDL3'; Key = 'SDL3' },
        @{ Repo = 'SDL_ttf'; Name = 'SDL3_ttf'; Key = 'SDL3_TTF' })) {
    $version = $Versions[$pkg.Key]
    $sha = $Versions["$($pkg.Key)_VC_SHA256"]
    if (-not $version -or -not $sha) { throw "sdl-versions.txt: $($pkg.Key) or $($pkg.Key)_VC_SHA256 is missing" }

    $zipName = "$($pkg.Name)-devel-$version-VC.zip"
    $zip = Join-Path $Download $zipName
    if (-not (Test-Path -LiteralPath $zip)) {
        $url = "https://github.com/libsdl-org/$($pkg.Repo)/releases/download/release-$version/$zipName"
        Write-Host "downloading: $url"
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    }
    $actual = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLower()
    if ($actual -ne $sha.ToLower()) {
        Remove-Item -LiteralPath $zip -Force
        throw "$zipName SHA256 mismatch: expected $sha, got $actual (file deleted)"
    }

    $dir = Join-Path $Windows "$($pkg.Name)-$version"
    if (-not (Test-Path -LiteralPath $dir)) { Expand-Archive -LiteralPath $zip -DestinationPath $Windows }
    $lib = Join-Path $dir 'lib\x64'
    Write-Host "$($pkg.Name) $version"
    Write-Host "  include: $(Join-Path $dir 'include')"
    Write-Host "  lib:     $(Join-Path $lib "$($pkg.Name).lib")"
    Write-Host "  dll:     $(Join-Path $lib "$($pkg.Name).dll")"
    $LibDirs += $lib
}

# Step 3 finding: for @[Link("SDL3")], iyi looks for SDL3.lib in the directories
# in IYI_LIBRARY_PATH and passes them to the linker (like Crystal's CRYSTAL_LIBRARY_PATH).
# LIB and --link-flags "/LIBPATH:..." also work; this one was chosen to have a single place.
$joined = $LibDirs -join ';'
$env:IYI_LIBRARY_PATH = (@($joined, $env:IYI_LIBRARY_PATH) | Where-Object { $_ }) -join ';'
$env:PATH = "$joined;$env:PATH"
if ($env:GITHUB_ENV) { "IYI_LIBRARY_PATH=$env:IYI_LIBRARY_PATH" | Out-File -Append -Encoding utf8 $env:GITHUB_ENV }
if ($env:GITHUB_PATH) { $LibDirs | Out-File -Append -Encoding utf8 $env:GITHUB_PATH }
Write-Host "IYI_LIBRARY_PATH=$env:IYI_LIBRARY_PATH"
Write-Host "added to PATH: $joined"
