$ErrorActionPreference = "Stop"

Write-Host "PULSE - validacao tecnica" -ForegroundColor Cyan

flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

dart format --output=none --set-exit-if-changed lib test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Validacao concluida. Confira o git status antes do commit." -ForegroundColor Green
git status
