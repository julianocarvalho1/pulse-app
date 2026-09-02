param(
  [Parameter(Mandatory = $true)]
  [string]$SourceDirectory
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$sourceRoot = (Resolve-Path -LiteralPath $SourceDirectory).Path
$sourceCatalogPath = Join-Path $sourceRoot 'exercises.json'
$sourceLicensePath = Join-Path $sourceRoot 'LICENSE-DATA.md'
$sourceAttributionPath = Join-Path $sourceRoot 'ATTRIBUTION.md'
$mappingPath = Join-Path $repoRoot 'lib\features\exercises\domain\repdb_exercise_mapping.dart'
$assetTarget = Join-Path $repoRoot 'assets\images'
$licenseTarget = Join-Path $repoRoot 'third_party\repdb'
$manifestTarget = Join-Path $licenseTarget 'ASSET-MANIFEST.sha256'

foreach ($requiredPath in @(
  $sourceCatalogPath,
  $sourceLicensePath,
  $sourceAttributionPath,
  $mappingPath
)) {
  if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
    throw "Arquivo obrigatório não encontrado: $requiredPath"
  }
}

$catalogDocument = Get-Content -Raw -LiteralPath $sourceCatalogPath |
  ConvertFrom-Json
$catalogById = @{}
foreach ($exercise in $catalogDocument.exercises) {
  $catalogById[$exercise.id] = $exercise
}

$mappingCode = Get-Content -Raw -LiteralPath $mappingPath
$exactMatches = [regex]::Matches(
  $mappingCode,
  "RepDbExerciseMatch\.exact\(\s*'([^']+)'"
)
$additionMatches = [regex]::Matches(
  $mappingCode,
  "RepDbCatalogAddition\(\s*repDbId:\s*'([^']+)'"
)
$sourceIds = @(
  @($exactMatches) + @($additionMatches) |
    ForEach-Object { $_.Groups[1].Value } |
    Sort-Object -Unique
)

if ($sourceIds.Count -ne 104) {
  throw "Esperados 104 exercícios aprovados, encontrados $($sourceIds.Count)."
}

New-Item -ItemType Directory -Force -Path $assetTarget | Out-Null
New-Item -ItemType Directory -Force -Path $licenseTarget | Out-Null

$copiedAssets = 0
$manifestEntries = @()
foreach ($sourceId in $sourceIds) {
  if (-not $catalogById.ContainsKey($sourceId)) {
    throw "ID RepDB não encontrado no catálogo oficial: $sourceId"
  }

  $flatImages = $catalogById[$sourceId].images.flat
  $relativePaths = @()
  if ($flatImages.start) { $relativePaths += $flatImages.start }
  if ($flatImages.peak) { $relativePaths += $flatImages.peak }
  if ($flatImages.main) { $relativePaths += $flatImages.main }

  if ($relativePaths.Count -lt 1 -or $relativePaths.Count -gt 2) {
    throw "Conjunto de imagens inesperado para $sourceId."
  }

  foreach ($relativePath in $relativePaths) {
    $sourceAsset = Join-Path $sourceRoot $relativePath
    if (-not (Test-Path -LiteralPath $sourceAsset -PathType Leaf)) {
      throw "Imagem oficial não encontrada: $sourceAsset"
    }

    $assetFileName = Split-Path -Leaf $relativePath
    $destinationAsset = Join-Path $assetTarget $assetFileName
    Copy-Item -LiteralPath $sourceAsset -Destination $destinationAsset -Force

    $sourceHash = (Get-FileHash -LiteralPath $sourceAsset -Algorithm SHA256).Hash
    $destinationHash = (
      Get-FileHash -LiteralPath $destinationAsset -Algorithm SHA256
    ).Hash
    if ($sourceHash -ne $destinationHash) {
      throw "Falha de integridade ao copiar: $assetFileName"
    }

    $manifestEntries += "$destinationHash  assets/images/$assetFileName"
    $copiedAssets++
  }
}

Copy-Item -LiteralPath $sourceLicensePath -Destination (
  Join-Path $licenseTarget 'LICENSE-DATA.md'
) -Force
Copy-Item -LiteralPath $sourceAttributionPath -Destination (
  Join-Path $licenseTarget 'ATTRIBUTION.md'
) -Force
[System.IO.File]::WriteAllLines(
  $manifestTarget,
  @(
    '# RepDB Free - SHA-256 manifest for bundled media'
    "# Source catalog: $((Get-FileHash -LiteralPath $sourceCatalogPath -Algorithm SHA256).Hash)  exercises.json"
    $manifestEntries | Sort-Object
  ),
  [System.Text.UTF8Encoding]::new($false)
)

Write-Output "RepDB: $($sourceIds.Count) exercícios aprovados."
Write-Output "RepDB: $copiedAssets imagens WebP importadas."
Write-Output "RepDB: manifesto de integridade salvo em $manifestTarget."
Write-Output "Destino: $assetTarget"
