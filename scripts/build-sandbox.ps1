param([string]$ApiBaseUrl = 'http://192.168.1.37:5000/api', [switch]$Run, [string]$DeviceId = '')
$ErrorActionPreference = 'Stop'
$appRoot = Split-Path $PSScriptRoot -Parent
$websiteEnv = Join-Path (Split-Path $appRoot -Parent) 'IEEE-Young-Prot-g-2026-Project--Food-Ordering-Web-Site/.env'
$keyLine = Get-Content -LiteralPath $websiteEnv | Where-Object { $_ -match '^\s*VITE_STRIPE_PUBLISHABLE_KEY\s*=' } | Select-Object -Last 1
if (!$keyLine) { throw 'Website test publishable key is missing.' }
$publishableKey = ($keyLine -split '=', 2)[1].Trim().Trim('"').Trim("'")
if ($publishableKey -notmatch '^pk_test_[A-Za-z0-9]+$') { throw 'A Stripe test publishable key is required.' }
$null = New-Item -ItemType Directory -Force -Path (Join-Path $appRoot '.dart_tool')
$configPath = Join-Path $appRoot '.dart_tool/stripe-sandbox-build.json'
@{ STRIPE_PUBLISHABLE_KEY = $publishableKey; API_BASE_URL = $ApiBaseUrl } | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding ascii
Push-Location $appRoot
try {
    # Capture Gradle command echo because it includes encoded Dart defines.
    $ErrorActionPreference = 'Continue'
    if ($Run) {
        $runArgs = @('run', '--debug', "--dart-define-from-file=$configPath")
        if ($DeviceId) { $runArgs += @('-d', $DeviceId) }
        & flutter @runArgs 2>&1 | ForEach-Object {
            if ([string]$_ -notmatch 'dart-defines|(?:pk|sk|rk)_(?:test|live)_') { Write-Output $_ }
        }
        if ($LASTEXITCODE -ne 0) { throw 'Flutter run failed.' }
        return
    }
    $buildOutput = & flutter build apk --debug --no-pub "--dart-define-from-file=$configPath" 2>&1
    $buildExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    foreach ($line in $buildOutput) {
        $safeLine = [string]$line
        if ($safeLine -match 'dart-defines|pk_test_|sk_test_') { continue }
        if ($safeLine -match 'error|failed|FAILURE|What went wrong|Built |BUILD |SDK|requires|Could not|Couldn.t|Exception|^\s*>') { Write-Output $safeLine }
    }
    if ($buildExit -ne 0) { throw "Sandbox APK build failed (exit $buildExit)." }
    Write-Output 'Sandbox APK ready: build/app/outputs/flutter-apk/app-debug.apk'
} finally {
    Pop-Location
    Remove-Item -LiteralPath $configPath -ErrorAction SilentlyContinue
}
