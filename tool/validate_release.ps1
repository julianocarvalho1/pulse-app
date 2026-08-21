param(
    [switch]$BuildAppBundle
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Invoke-NativeStep([string]$Label, [scriptblock]$Command) {
    Write-Host "`n> $Label" -ForegroundColor Cyan
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Label falhou com codigo $LASTEXITCODE."
    }
}

Push-Location $repoRoot
try {
    Write-Host "PULSE - validacao tecnica" -ForegroundColor Cyan

    Invoke-NativeStep "Instalar dependencias" { flutter pub get }
    Invoke-NativeStep "Verificar formatacao" {
        dart format --output=none --set-exit-if-changed lib test
    }
    Invoke-NativeStep "Analisar codigo" { flutter analyze }
    Invoke-NativeStep "Executar testes" { flutter test }
    Invoke-NativeStep "Compilar APK de depuracao" { flutter build apk --debug }

    if ($BuildAppBundle) {
        $propertiesPath = Join-Path $repoRoot "android\key.properties"
        $inventoryPath = Join-Path $repoRoot "docs\google-play\inventario-licencas-midias.csv"

        if (-not (Test-Path $propertiesPath)) {
            throw "Assinatura ausente. Configure android\key.properties com a chave de upload existente."
        }
        foreach ($requiredProperty in @("storeFile", "storePassword", "keyAlias", "keyPassword")) {
            if (-not (Select-String -Path $propertiesPath -Pattern "^$requiredProperty\s*=\s*\S+" -Quiet)) {
                throw "Propriedade de assinatura ausente ou vazia: $requiredProperty"
            }
        }
        $storeFileLine = Select-String -Path $propertiesPath -Pattern '^storeFile\s*=\s*(.+)$' |
            Select-Object -First 1
        $configuredStoreFile = $storeFileLine.Matches[0].Groups[1].Value.Trim()
        $configuredStorePath = if ([IO.Path]::IsPathRooted($configuredStoreFile)) {
            $configuredStoreFile
        }
        else {
            Join-Path (Join-Path $repoRoot "android") $configuredStoreFile
        }
        if (-not (Test-Path -LiteralPath $configuredStorePath)) {
            throw "Chave de upload nao encontrada no caminho configurado em storeFile."
        }
        if (-not (Test-Path $inventoryPath)) {
            throw "Inventario de licencas de midia ausente: $inventoryPath"
        }
        if (Select-String -Path $inventoryPath -Pattern 'PENDENTE' -Quiet) {
            throw "Ha midias sem origem/licenca comprovada. Resolva os itens PENDENTE antes da publicacao."
        }

        Invoke-NativeStep "Gerar Android App Bundle assinado" {
            flutter build appbundle --release
        }

        $bundlePath = Join-Path $repoRoot "build\app\outputs\bundle\release\app-release.aab"
        if (-not (Test-Path $bundlePath)) {
            throw "AAB nao encontrado apos o build: $bundlePath"
        }

        $jarsignerCommand = Get-Command jarsigner -ErrorAction SilentlyContinue
        if ($jarsignerCommand) {
            $jarsignerPath = $jarsignerCommand.Source
        }
        else {
            $androidStudioJarsigner = "C:\Program Files\Android\Android Studio\jbr\bin\jarsigner.exe"
            if (Test-Path $androidStudioJarsigner) {
                $jarsignerPath = $androidStudioJarsigner
            }
        }

        if (-not $jarsignerPath) {
            throw "jarsigner nao encontrado; nao e seguro liberar o AAB sem verificar a assinatura."
        }

        Write-Host "`n> Verificar assinatura do AAB" -ForegroundColor Cyan
        $signatureOutput = @(
            & $jarsignerPath `
                '-J-Duser.language=en' `
                '-J-Duser.country=US' `
                -verify `
                $bundlePath 2>&1
        )
        $signatureExitCode = $LASTEXITCODE
        $signatureText = ($signatureOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        if (
            $signatureExitCode -ne 0 -or
            $signatureText -notmatch '(?im)^\s*jar verified\.\s*$' -or
            $signatureText -match '(?im)jar is unsigned'
        ) {
            throw "O AAB nao possui uma assinatura valida da chave de upload."
        }
        Write-Host "Assinatura do AAB confirmada." -ForegroundColor Green

        $bundleFile = Get-Item -LiteralPath $bundlePath
        $bundleHash = Get-FileHash -LiteralPath $bundlePath -Algorithm SHA256

        Write-Host "`nAAB pronto: $bundlePath" -ForegroundColor Green
        Write-Host "Tamanho: $($bundleFile.Length) bytes"
        Write-Host "SHA-256: $($bundleHash.Hash)"
    }

    Write-Host "`nValidacao concluida. Confira o git status antes do commit." -ForegroundColor Green
    git status --short
}
finally {
    Pop-Location
}
