# docker-image.ps1 - PowerShell version for Windows
# Skrypt do tworzenia obrazów Docker dla różnych platform
#
# Copyright 2025 Marcin Chuć ORCID: 0000-0002-8430-9763
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

param(
    [string]$OutputDir = ".\docker-images",
    [string]$ImageName = "barking-dog-api",
    [string]$Version = "latest"
)

# Kolory PowerShell
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Cyan"

Write-Host "🐳 Barking Dog API - Tworzenie obrazów Docker" -ForegroundColor $Blue
Write-Host "==================================================" -ForegroundColor $Blue

# Sprawdź czy Docker jest zainstalowany
try {
    docker --version | Out-Null
    Write-Host "✅ Docker jest dostępny" -ForegroundColor $Green
} catch {
    Write-Host "❌ Docker nie jest zainstalowany" -ForegroundColor $Red
    exit 1
}

# Sprawdź czy Docker Buildx jest dostępny
try {
    docker buildx version | Out-Null
    Write-Host "✅ Docker Buildx dostępny - budowanie multi-platform" -ForegroundColor $Green
    $BuildxAvailable = $true
} catch {
    Write-Host "⚠️  Docker Buildx niedostępny - używam standardowego build" -ForegroundColor $Yellow
    $BuildxAvailable = $false
}

# Utwórz katalog wyjściowy
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# Funkcja do budowania i eksportowania obrazu
function Build-And-Export {
    param(
        [string]$Platform,
        [string]$ArchName
    )
    
    $FullImageName = "${ImageName}:${Version}-${ArchName}"
    $OutputFile = "${OutputDir}\barkingDog-img-${ArchName}.tar.gz"
    
    Write-Host "`n🔨 Budowanie obrazu dla $Platform ($ArchName)..." -ForegroundColor $Blue
    
    if ($BuildxAvailable) {
        # Użyj buildx dla multi-platform
        docker buildx build --platform $Platform --tag $FullImageName --load .
    } else {
        # Standardowe budowanie (tylko dla natywnej platformy)
        if ($ArchName -eq "native") {
            docker build -t $FullImageName .
        } else {
            Write-Host "⚠️  Pomijam $ArchName - Buildx niedostępny" -ForegroundColor $Yellow
            return
        }
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Obraz $ArchName zbudowany pomyślnie" -ForegroundColor $Green
        
        # Eksportuj obraz do pliku tar.gz
        Write-Host "📦 Eksportowanie do $OutputFile..." -ForegroundColor $Blue
        
        # Windows nie ma natywnego gzip, więc używamy 7zip lub Docker save + kompresja
        docker save $FullImageName | 7z a -si $OutputFile
        
        if ($LASTEXITCODE -eq 0) {
            $FileSize = (Get-Item $OutputFile).Length
            $FileSizeMB = [math]::Round($FileSize / 1MB, 2)
            Write-Host "✅ Wyeksportowano: $OutputFile ($FileSizeMB MB)" -ForegroundColor $Green
            
            # Dodaj informacje o obrazie do pliku
            "- ${ArchName}: $OutputFile ($FileSizeMB MB)" | Add-Content "${OutputDir}\images-info.txt"
        } else {
            Write-Host "❌ Błąd podczas eksportowania $ArchName" -ForegroundColor $Red
        }
    } else {
        Write-Host "❌ Błąd podczas budowania $ArchName" -ForegroundColor $Red
    }
}

# Wyczyść poprzednie informacje
"Barking Dog API - Docker Images" | Set-Content "${OutputDir}\images-info.txt"
"Utworzono: $(Get-Date)" | Add-Content "${OutputDir}\images-info.txt"
"===============================" | Add-Content "${OutputDir}\images-info.txt"

# Buduj obrazy dla różnych platform
if ($BuildxAvailable) {
    # Utwórz builder dla multi-platform
    docker buildx create --name multiplatform-builder --use --bootstrap 2>$null
    
    Write-Host "`n🏗️  Budowanie obrazów dla wszystkich platform..." -ForegroundColor $Blue
    
    # Linux AMD64
    Build-And-Export "linux/amd64" "linux-amd64"
    
    # Linux ARM64 (Raspberry Pi 4)
    Build-And-Export "linux/arm64" "raspberry-pi"
    
    # Linux ARM v7 (starsze Raspberry Pi)
    Build-And-Export "linux/arm/v7" "raspberry-pi-armv7"
    
} else {
    Write-Host "`n🏗️  Budowanie obrazu dla natywnej platformy..." -ForegroundColor $Blue
    Build-And-Export "native" "native"
}

# Stwórz skrypty importu
Write-Host "`n📝 Tworzenie skryptów importu..." -ForegroundColor $Blue

# Skrypt PowerShell do importu
@"
# import-image.ps1 - Import Docker image
param([string]`$ImageFile)

if (-not `$ImageFile -or -not (Test-Path `$ImageFile)) {
    Write-Host "❌ Użycie: .\import-image.ps1 <plik-obrazu.tar.gz>" -ForegroundColor Red
    Write-Host "Dostępne pliki:" -ForegroundColor Yellow
    Get-ChildItem *.tar.gz | Format-Table Name, Length
    exit 1
}

Write-Host "📦 Importowanie z pliku: `$ImageFile" -ForegroundColor Cyan
7z x "`$ImageFile" -so | docker load

if (`$LASTEXITCODE -eq 0) {
    Write-Host "✅ Obraz zaimportowany pomyślnie!" -ForegroundColor Green
    Write-Host "🚀 Uruchom: docker run -d -p 8000:8000 barking-dog-api:latest-*" -ForegroundColor Blue
    Write-Host "📋 Zobacz obrazy: docker images | findstr barking-dog" -ForegroundColor Blue
} else {
    Write-Host "❌ Błąd podczas importowania" -ForegroundColor Red
}
"@ | Set-Content "${OutputDir}\import-image.ps1"

# Skrypt batch do importu
@"
@echo off
REM import-image.bat - Import Docker image

if "%1"=="" (
    echo ❌ Użycie: %0 ^<plik-obrazu.tar.gz^>
    echo Dostępne pliki:
    dir *.tar.gz 2>nul
    pause
    exit /b 1
)

echo 📦 Importowanie z pliku: %1
7z x "%1" -so | docker load

if %errorlevel% equ 0 (
    echo ✅ Obraz zaimportowany pomyślnie!
    echo 🚀 Uruchom: docker run -d -p 8000:8000 barking-dog-api:latest-*
    echo 📋 Zobacz obrazy: docker images ^| findstr barking-dog
) else (
    echo ❌ Błąd podczas importowania
)
pause
"@ | Set-Content "${OutputDir}\import-image.bat"

# Stwórz README
@"
# 🐳 Barking Dog API - Docker Images (Windows)

Gotowe obrazy Docker dla różnych platform - utworzone na Windows.

## 📦 Wymagania

- Docker Desktop dla Windows
- 7-Zip (do kompresji/dekompresji)

## 🚀 Szybkie uruchomienie

### PowerShell:
``````powershell
# Importuj obraz
.\import-image.ps1 barkingDog-img-linux-amd64.tar.gz

# Uruchom
docker run -d -p 8000:8000 barking-dog-api:latest-linux-amd64
``````

### Command Prompt:
``````bat
REM Importuj obraz
import-image.bat barkingDog-img-linux-amd64.tar.gz

REM Uruchom
docker run -d -p 8000:8000 barking-dog-api:latest-linux-amd64
``````

## 🔧 Test API

``````powershell
# PowerShell
Invoke-RestMethod -Uri "http://localhost:8000/warn" -Method POST

# Curl (jeśli zainstalowany)
curl -X POST http://localhost:8000/warn
``````
"@ | Set-Content "${OutputDir}\README-Windows.md"

# Podsumowanie
Write-Host "`n🎉 Proces zakończony!" -ForegroundColor $Green
Write-Host "📁 Pliki utworzone w katalogu: $OutputDir" -ForegroundColor $Blue
Write-Host ""
Write-Host "📋 Dostępne pliki:" -ForegroundColor $Yellow
Get-ChildItem $OutputDir | Format-Table Name, Length
Write-Host ""
Write-Host "✅ Gotowe obrazy Docker można przenieść na inne maszyny!" -ForegroundColor $Green
Write-Host "ℹ️  Instrukcje użycia w: $OutputDir\README-Windows.md" -ForegroundColor $Blue

# Wyświetl informacje o obrazach
if (Test-Path "${OutputDir}\images-info.txt") {
    Write-Host "`n📊 Utworzone obrazy:" -ForegroundColor $Blue
    Get-Content "${OutputDir}\images-info.txt"
}

Write-Host "`n🚀 Teraz możesz przenieść katalog $OutputDir na inne maszyny!" -ForegroundColor $Green