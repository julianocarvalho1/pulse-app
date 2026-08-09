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
$sourceIds = @(
  $exactMatches |
    ForEach-Object { $_.Groups[1].Value } |
    Sort-Object -Unique
)

if ($sourceIds.Count -ne 57) {
  throw "Esperados 57 exercícios aprovados, encontrados $($sourceIds.Count)."
}

New-Item -ItemType Directory -Force -Path $assetTarget | Out-Null
New-Item -ItemType Directory -Force -Path $licenseTarget | Out-Null

$copiedAssets = 0
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

    $destinationAsset = Join-Path $assetTarget (
      Split-Path -Leaf $relativePath
    )
    Copy-Item -LiteralPath $sourceAsset -Destination $destinationAsset -Force
    $copiedAssets++
  }
}

Copy-Item -LiteralPath $sourceLicensePath -Destination (
  Join-Path $licenseTarget 'LICENSE-DATA.md'
) -Force
Copy-Item -LiteralPath $sourceAttributionPath -Destination (
  Join-Path $licenseTarget 'ATTRIBUTION.md'
) -Force

Write-Output "RepDB: $($sourceIds.Count) exercícios aprovados."
Write-Output "RepDB: $copiedAssets imagens WebP importadas."
Write-Output "Destino: $assetTarget"
