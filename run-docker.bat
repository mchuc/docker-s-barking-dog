@echo off
REM Uruchomienie dla Windows
REM
REM Copyright 2025 Marcin Chuć ORCID: 0000-0002-8430-9763
REM
REM Licensed under the Apache License, Version 2.0 (the "License");
REM you may not use this file except in compliance with the License.
REM You may obtain a copy of the License at
REM
REM     http://www.apache.org/licenses/LICENSE-2.0
REM
REM Unless required by applicable law or agreed to in writing, software
REM distributed under the License is distributed on an "AS IS" BASIS,
REM WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
REM See the License for the specific language governing permissions and
REM limitations under the License.

echo === Barking Dog API - Uruchomienie Docker ===

REM Sprawdz czy Docker jest zainstalowany
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Docker nie jest zainstalowany. Zainstaluj Docker Desktop.
    pause
    exit /b 1
)

REM Sprawdz czy docker-compose jest dostepny
where docker-compose >nul 2>nul
if %errorlevel% neq 0 (
    docker compose version >nul 2>nul
    if %errorlevel% neq 0 (
        echo ❌ Docker Compose nie jest dostepny.
        pause
        exit /b 1
    )
)

echo ✅ Docker i Docker Compose sa dostepne

REM Zbuduj i uruchom kontener
echo 🔨 Budowanie obrazu Docker...
docker-compose build

if %errorlevel% equ 0 (
    echo ✅ Obraz zbudowany pomyslnie
    echo 🚀 Uruchamianie kontenera...
    docker-compose up -d
    
    echo.
    echo 🎉 Aplikacja uruchomiona!
    echo 📡 API dostepne na: http://localhost:8000
    echo 📖 Dokumentacja API: http://localhost:8000/docs
    echo 🔊 Test endpoint: curl -X POST http://localhost:8000/warn
    echo.
    echo 📋 Przydatne komendy:
    echo   docker-compose logs -f      # Zobacz logi
    echo   docker-compose stop         # Zatrzymaj
    echo   docker-compose down         # Zatrzymaj i usun kontener
    echo.
    pause
) else (
    echo ❌ Blad podczas budowania obrazu
    pause
    exit /b 1
)