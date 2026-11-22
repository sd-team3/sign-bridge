param(
    [string]$ImportFrom,
    [switch]$BuildOnly,
    [switch]$PrepareOnly
)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
& docker info --format '{{.ServerVersion}}' | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Start Docker Desktop in Linux container mode first.' }

$envPath = Join-Path $PSScriptRoot '.env'
if (-not $ImportFrom -and -not (Test-Path -LiteralPath $envPath)) {
    $previousDeployment = 'C:\SignBridge-Laptop'
    if ((Test-Path -LiteralPath "$previousDeployment\.env") -and
        [IO.Path]::GetFullPath($previousDeployment) -ne $PSScriptRoot) {
        $ImportFrom = $previousDeployment
    }
}

function Set-DeploymentSetting([string]$Content, [string]$Key, [string]$Value) {
    $pattern = '(?m)^' + [regex]::Escape($Key) + '=[^\r\n]*'
    if ([regex]::IsMatch($Content, $pattern)) {
        return [regex]::Replace($Content, $pattern, [Text.RegularExpressions.MatchEvaluator]{ param($m) "$Key=$Value" })
    }
    return $Content.TrimEnd() + "`n$Key=$Value`n"
}

if ($ImportFrom) {
    $oldRoot = (Resolve-Path -LiteralPath $ImportFrom).Path
    $oldEnv = Join-Path $oldRoot '.env'
    $oldCompose = Join-Path $oldRoot 'docker-compose.graduation.yml'
    if (-not (Test-Path -LiteralPath $oldEnv) -or -not (Test-Path -LiteralPath $oldCompose)) {
        throw 'The previous deployment must contain .env and docker-compose.graduation.yml.'
    }
    $oldJson = & docker compose --project-directory $oldRoot --env-file $oldEnv -f $oldCompose config --format json
    if ($LASTEXITCODE -ne 0) { throw 'Could not read the previous deployment configuration.' }
    $oldConfig = ($oldJson -join "`n") | ConvertFrom-Json
    $settings = [IO.File]::ReadAllText($oldEnv)
    $settings = Set-DeploymentSetting $settings 'SIGNBRIDGE_PROJECT_NAME' $oldConfig.name
    $volumeSettings = @{
        mysql_data = 'SIGNBRIDGE_MYSQL_VOLUME'
        search_data = 'SIGNBRIDGE_SEARCH_VOLUME'
        python_data = 'SIGNBRIDGE_PYTHON_DATA_VOLUME'
        python_models = 'SIGNBRIDGE_PYTHON_MODELS_VOLUME'
        uploads = 'SIGNBRIDGE_UPLOADS_VOLUME'
    }
    foreach ($entry in $volumeSettings.GetEnumerator()) {
        $volume = $oldConfig.volumes.PSObject.Properties[$entry.Key].Value.name
        if (-not $volume) { throw "The previous deployment has no volume mapping for $($entry.Key)." }
        & docker volume inspect $volume 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Existing data volume was not found: $volume" }
        $settings = Set-DeploymentSetting $settings $entry.Value $volume
    }
    if (Test-Path -LiteralPath $envPath) {
        $backup = "$envPath.previous-$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')"
        Copy-Item -LiteralPath $envPath -Destination $backup
    }
    [IO.File]::WriteAllText($envPath, $settings, [Text.UTF8Encoding]::new($false))
    Write-Host 'Imported the deployment settings and existing Docker volume names.'
}

if (-not (Test-Path -LiteralPath $envPath)) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot '.env.example') -Destination $envPath
    Write-Host 'Created .env for local use. Set the public URL and OAuth credentials there for public hosting.'
}
$settings = [IO.File]::ReadAllText($envPath)
$match = [regex]::Match($settings, '(?m)^SIGNBRIDGE_PUBLIC_URL=([^\r\n]*)')
if (-not $match.Success) { throw 'Set SIGNBRIDGE_PUBLIC_URL in .env.' }
$publicUrl = $match.Groups[1].Value.Trim().Trim([char]39, [char]34).TrimEnd('/')
$uri = $null
if (-not [Uri]::TryCreate($publicUrl, [UriKind]::Absolute, [ref]$uri) -or
    $uri.Scheme -notin @('http', 'https') -or $uri.AbsolutePath -ne '/' -or $uri.Query -or $uri.Fragment) {
    throw 'SIGNBRIDGE_PUBLIC_URL must be an http(s) origin without a path, query or fragment.'
}
$settings = Set-DeploymentSetting $settings 'SIGNBRIDGE_PUBLIC_URL' $publicUrl
[IO.File]::WriteAllText($envPath, $settings, [Text.UTF8Encoding]::new($false))
$env:SIGNBRIDGE_PUBLIC_URL = $publicUrl

& docker compose -f docker-compose.yml config --quiet
if ($LASTEXITCODE -ne 0) { throw 'The Compose configuration is invalid.' }
if ($PrepareOnly) { Write-Host 'Deployment configuration is ready.'; return }

# Build the checked-out sources before replacing any running application.
& docker compose -f docker-compose.yml build
if ($LASTEXITCODE -ne 0) { throw 'Build failed. Check the output above before restarting.' }
if ($BuildOnly) { Write-Host 'Current branch images are ready.'; return }

& docker compose -f docker-compose.yml up -d --no-build --wait --wait-timeout 240
if ($LASTEXITCODE -ne 0) {
    & docker compose -f docker-compose.yml ps -a
    throw 'Startup failed. Inspect docker compose logs --tail 80.'
}
Write-Host "SignBridge is ready. Public origin: $publicUrl"
