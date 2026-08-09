param(
    [string]$Alias = "upload",
    [string]$DistinguishedName = "CN=PULSE Upload, OU=Julianoapps, O=Julianoapps, C=BR"
)

$ErrorActionPreference = "Stop"

function Convert-ToPlainText([Security.SecureString]$SecureValue) {
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
}

function Convert-ToJavaProperty([string]$Value) {
    return $Value.Replace("\", "\\").Replace(":", "\:").Replace("=", "\=")
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$androidRoot = Join-Path $repoRoot "android"
$keystorePath = Join-Path $androidRoot "upload-keystore.jks"
$propertiesPath = Join-Path $androidRoot "key.properties"

if ((Test-Path $keystorePath) -or (Test-Path $propertiesPath)) {
    throw "A assinatura ja parece configurada. Nada foi sobrescrito: $keystorePath / $propertiesPath"
}

$keytoolCommand = Get-Command keytool -ErrorAction SilentlyContinue
if ($keytoolCommand) {
    $keytoolPath = $keytoolCommand.Source
}
else {
    $androidStudioKeytool = "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
    if (Test-Path $androidStudioKeytool) {
        $keytoolPath = $androidStudioKeytool
    }
    else {
        throw "keytool nao encontrado. Instale/abra o Android Studio e tente novamente."
    }
}

Write-Host "PULSE - criacao da chave de upload da Google Play" -ForegroundColor Cyan
Write-Host "Use uma senha exclusiva com pelo menos 12 caracteres e guarde-a fora do computador." -ForegroundColor Yellow

$securePassword = Read-Host "Senha da chave" -AsSecureString
$secureConfirmation = Read-Host "Repita a senha" -AsSecureString
$password = Convert-ToPlainText $securePassword
$confirmation = Convert-ToPlainText $secureConfirmation

if ($password.Length -lt 12) {
    throw "A senha precisa ter pelo menos 12 caracteres."
}
if ($password -cne $confirmation) {
    throw "As senhas nao coincidem."
}

try {
    & $keytoolPath `
        -genkeypair `
        -v `
        -keystore $keystorePath `
        -storetype JKS `
        -alias $Alias `
        -keyalg RSA `
        -keysize 2048 `
        -validity 10000 `
        -storepass $password `
        -keypass $password `
        -dname $DistinguishedName

    if ($LASTEXITCODE -ne 0) {
        throw "O keytool terminou com codigo $LASTEXITCODE."
    }

    $escapedPassword = Convert-ToJavaProperty $password
    $escapedAlias = Convert-ToJavaProperty $Alias
    $properties = @(
        "storePassword=$escapedPassword"
        "keyPassword=$escapedPassword"
        "keyAlias=$escapedAlias"
        "storeFile=upload-keystore.jks"
        ""
    ) -join [Environment]::NewLine
    [IO.File]::WriteAllText($propertiesPath, $properties, [Text.UTF8Encoding]::new($false))

    Write-Host "Chave criada com sucesso." -ForegroundColor Green
    Write-Host "Faca agora duas copias offline de:" -ForegroundColor Yellow
    Write-Host "  $keystorePath"
    Write-Host "  $propertiesPath"
    Write-Host "Sem esses arquivos e a senha, futuras atualizacoes podem ficar impossiveis."
}
catch {
    if ((Test-Path $keystorePath) -and -not (Test-Path $propertiesPath)) {
        Write-Warning "A chave foi criada, mas key.properties nao. Preserve a chave e corrija a configuracao manualmente."
    }
    throw
}
finally {
    $password = $null
    $confirmation = $null
}
