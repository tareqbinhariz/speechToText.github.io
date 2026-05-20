# Aswat - Speech to Text Deployment Script
# This script compiles the Flutter project and deploys the built web files to the root repository for GitHub Pages.

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   🚀 Aswat Web Deployer & Builder        " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Build the Flutter Web App
Write-Host "`n[1/3] Compiling Flutter Web Application (Release Mode)..." -ForegroundColor Yellow
cd project
flutter build web --release --no-wasm-dry-run

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ Flutter compilation failed! Deployment aborted." -ForegroundColor Red
    cd ..
    Exit $LASTEXITCODE
}

# 2. Copy compiled assets to the root directory
Write-Host "`n[2/3] Syncing built assets to root repository folder..." -ForegroundColor Yellow
cd ..
Copy-Item -Recurse -Force project/build/web/* .

# 3. Handle Git staging and status
Write-Host "`n[3/3] Staging compiled assets in Git..." -ForegroundColor Yellow
git add index.html main.dart.js flutter.js flutter_bootstrap.js flutter_service_worker.js favicon.png manifest.json version.json assets/ canvaskit/ icons/
if (Test-Path main.dart.mjs) { git rm main.dart.mjs --ignore-unmatch }
if (Test-Path main.dart.wasm) { git rm main.dart.wasm --ignore-unmatch }

Write-Host "`n==========================================" -ForegroundColor Green
Write-Host "   ✅ Build & Staging Complete!           " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

Write-Host "`nCurrent Git Status:" -ForegroundColor Cyan
git status

Write-Host "`n💡 To publish these changes to your GitHub Pages site, run:" -ForegroundColor Magenta
Write-Host "   git commit -m 'deploy: update compiled web release'" -ForegroundColor Magenta
Write-Host "   git push origin master" -ForegroundColor Magenta
