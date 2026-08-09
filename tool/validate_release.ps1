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

        if ($jarsignerPath) {
            Invoke-NativeStep "Verificar assinatura do AAB" {
                & $jarsignerPath -verify -strict -certs $bundlePath
            }
        }
        else {
            Write-Warning "jarsigner nao encontrado; a assinatura do AAB nao foi verificada separadamente."
        }

        Write-Host "`nAAB pronto: $bundlePath" -ForegroundColor Green
    }

    Write-Host "`nValidacao concluida. Confira o git status antes do commit." -ForegroundColor Green
    git status --short
}
finally {
    Pop-Location
}
