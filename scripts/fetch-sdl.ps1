<#
    SDL3 ve SDL3_ttf'nin Visual C++ geliştirme paketlerini (-VC.zip) indirir,
    sdl-versions.txt'teki SHA256 ile doğrular ve vendor/windows/ altına açar.
    Sonunda iyi'nin linkleyicisi ve çalışan program için ortamı ayarlar:

      IYI_LIBRARY_PATH  SDL3.lib / SDL3_ttf.lib dizinleri (iyi bunları MSVC
                        linkleyicisine /LIBPATH olarak verir)
      PATH              SDL3.dll / SDL3_ttf.dll dizinleri (program çalışırken)

    Ortamın oturumda kalması için nokta ile çalıştırın:

      . .\scripts\fetch-sdl.ps1

    GitHub Actions'ta GITHUB_ENV / GITHUB_PATH'e de yazar, sonraki adımlar görür.
#>
$ErrorActionPreference = 'Stop'
# Windows PowerShell 5.1 eski bir TLS ile başlayabilir; GitHub 1.2 ister.
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
    if (-not $version -or -not $sha) { throw "sdl-versions.txt: $($pkg.Key) ya da $($pkg.Key)_VC_SHA256 yok" }

    $zipName = "$($pkg.Name)-devel-$version-VC.zip"
    $zip = Join-Path $Download $zipName
    if (-not (Test-Path -LiteralPath $zip)) {
        $url = "https://github.com/libsdl-org/$($pkg.Repo)/releases/download/release-$version/$zipName"
        Write-Host "indiriliyor: $url"
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    }
    $actual = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLower()
    if ($actual -ne $sha.ToLower()) {
        Remove-Item -LiteralPath $zip -Force
        throw "$zipName SHA256 tutmuyor: beklenen $sha, gelen $actual (dosya silindi)"
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

# Step 3 bulgusu: iyi, @[Link("SDL3")] için SDL3.lib'i IYI_LIBRARY_PATH'teki
# dizinlerde arar ve linkleyiciye verir (Crystal'ın CRYSTAL_LIBRARY_PATH'i gibi).
# LIB ve --link-flags "/LIBPATH:..." de çalışıyor; tek yer olsun diye bu seçildi.
$joined = $LibDirs -join ';'
$env:IYI_LIBRARY_PATH = (@($joined, $env:IYI_LIBRARY_PATH) | Where-Object { $_ }) -join ';'
$env:PATH = "$joined;$env:PATH"
if ($env:GITHUB_ENV) { "IYI_LIBRARY_PATH=$env:IYI_LIBRARY_PATH" | Out-File -Append -Encoding utf8 $env:GITHUB_ENV }
if ($env:GITHUB_PATH) { $LibDirs | Out-File -Append -Encoding utf8 $env:GITHUB_PATH }
Write-Host "IYI_LIBRARY_PATH=$env:IYI_LIBRARY_PATH"
Write-Host "PATH'e eklendi: $joined"
