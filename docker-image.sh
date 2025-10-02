#!/bin/bash
# docker-image.sh - Skrypt do tworzenia obrazów Docker dla różnych platform
# Tworzy obrazy dla Windows, Linux, macOS i Raspberry Pi
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

set -e  # Przerwij na błędzie

# Kolory dla lepszej czytelności
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Konfiguracja
IMAGE_NAME="barking-dog-api"
VERSION="latest"
OUTPUT_DIR="./docker-images"

echo -e "${BLUE}🐳 Barking Dog API - Tworzenie obrazów Docker${NC}"
echo "=================================================="

# Sprawdź czy Docker jest zainstalowany
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker nie jest zainstalowany${NC}"
    exit 1
fi

# Sprawdź czy Docker Buildx jest dostępny (dla multi-platform)
if ! docker buildx version &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker Buildx niedostępny - używam standardowego build${NC}"
    BUILDX_AVAILABLE=false
else
    echo -e "${GREEN}✅ Docker Buildx dostępny - budowanie multi-platform${NC}"
    BUILDX_AVAILABLE=true
fi

# Utwórz katalog wyjściowy
mkdir -p "$OUTPUT_DIR"

# Funkcja do budowania i eksportowania obrazu
build_and_export() {
    local platform=$1
    local arch_name=$2
    local full_image_name="${IMAGE_NAME}:${VERSION}-${arch_name}"
    local output_file="${OUTPUT_DIR}/barkingDog-img-${arch_name}.tar.gz"
    
    echo -e "\n${BLUE}🔨 Budowanie obrazu dla ${platform} (${arch_name})...${NC}"
    
    if [ "$BUILDX_AVAILABLE" = true ]; then
        # Użyj buildx dla multi-platform
        docker buildx build \
            --platform "$platform" \
            --tag "$full_image_name" \
            --load \
            .
    else
        # Standardowe budowanie (tylko dla natywnej platformy)
        if [ "$arch_name" = "native" ]; then
            docker build -t "$full_image_name" .
        else
            echo -e "${YELLOW}⚠️  Pomijam ${arch_name} - Buildx niedostępny${NC}"
            return
        fi
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Obraz ${arch_name} zbudowany pomyślnie${NC}"
        
        # Eksportuj obraz do pliku tar.gz
        echo -e "${BLUE}📦 Eksportowanie do ${output_file}...${NC}"
        docker save "$full_image_name" | gzip > "$output_file"
        
        if [ $? -eq 0 ]; then
            # Sprawdź rozmiar pliku
            local file_size=$(du -h "$output_file" | cut -f1)
            echo -e "${GREEN}✅ Wyeksportowano: ${output_file} (${file_size})${NC}"
            
            # Dodaj informacje o obrazie do README
            echo "- ${arch_name}: ${output_file} (${file_size})" >> "${OUTPUT_DIR}/images-info.txt"
        else
            echo -e "${RED}❌ Błąd podczas eksportowania ${arch_name}${NC}"
        fi
    else
        echo -e "${RED}❌ Błąd podczas budowania ${arch_name}${NC}"
    fi
}

# Wyczyść poprzednie informacje
rm -f "${OUTPUT_DIR}/images-info.txt"
echo "Barking Dog API - Docker Images" > "${OUTPUT_DIR}/images-info.txt"
echo "Utworzono: $(date)" >> "${OUTPUT_DIR}/images-info.txt"
echo "===============================" >> "${OUTPUT_DIR}/images-info.txt"

# Buduj obrazy dla różnych platform
if [ "$BUILDX_AVAILABLE" = true ]; then
    # Utwórz builder dla multi-platform (jeśli nie istnieje)
    docker buildx create --name multiplatform-builder --use --bootstrap 2>/dev/null || true
    
    echo -e "\n${BLUE}🏗️  Budowanie obrazów dla wszystkich platform...${NC}"
    
    # Linux AMD64 (standardowe serwery, PC)
    build_and_export "linux/amd64" "linux-amd64"
    
    # Linux ARM64 (Raspberry Pi 4, Apple Silicon, AWS Graviton)
    build_and_export "linux/arm64" "raspberry-pi"
    
    # Linux ARM v7 (starsze Raspberry Pi)
    build_and_export "linux/arm/v7" "raspberry-pi-armv7"
    
    # Windows AMD64
    # Uwaga: Windows containers wymagają Windows base image
    echo -e "\n${YELLOW}ℹ️  Windows: Używam Linux obrazu (działa na Windows Docker Desktop)${NC}"
    # Windows containers są skomplikowane, więc używamy Linux obrazu który działa na Windows Docker Desktop
    
    # iOS ARM64 (kompatybilny z nowymi iPhone/iPad z M-chipami Apple)
    build_and_export "linux/arm64" "ios-arm64"

else
    echo -e "\n${BLUE}🏗️  Budowanie obrazu dla natywnej platformy...${NC}"
    build_and_export "native" "native"
fi

# Stwórz skrypty importu dla każdej platformy
echo -e "\n${BLUE}📝 Tworzenie skryptów importu...${NC}"

# Skrypt importu dla Linux/macOS
cat > "${OUTPUT_DIR}/import-linux-mac.sh" << 'EOF'
#!/bin/bash
# Skrypt importu dla Linux/macOS

echo "🐳 Importowanie obrazu Barking Dog API"

# Sprawdź czy plik istnieje
if [ ! -f "$1" ]; then
    echo "❌ Użycie: $0 <plik-obrazu.tar.gz>"
    echo "Dostępne pliki:"
    ls -la *.tar.gz 2>/dev/null || echo "Brak plików .tar.gz"
    exit 1
fi

echo "📦 Importowanie z pliku: $1"
gunzip -c "$1" | docker load

if [ $? -eq 0 ]; then
    echo "✅ Obraz zaimportowany pomyślnie!"
    echo "🚀 Uruchom: docker run -d -p 8000:8000 barking-dog-api:latest-*"
    echo "📋 Zobacz obrazy: docker images | grep barking-dog"
else
    echo "❌ Błąd podczas importowania"
fi
EOF

# Skrypt importu dla Windows
cat > "${OUTPUT_DIR}/import-windows.bat" << 'EOF'
@echo off
REM Skrypt importu dla Windows

echo 🐳 Importowanie obrazu Barking Dog API

if "%1"=="" (
    echo ❌ Użycie: %0 ^<plik-obrazu.tar.gz^>
    echo Dostępne pliki:
    dir *.tar.gz 2>nul || echo Brak plików .tar.gz
    pause
    exit /b 1
)

echo 📦 Importowanie z pliku: %1
7z x "%1" -so | docker load

if %errorlevel% equ 0 (
    echo ✅ Obraz zaimportowany pomyślnie!
    echo 🚀 Uruchom: docker run -d -p 8000:8000 barking-dog-api:latest-*
    echo 📋 Zobacz obrazy: docker images | findstr barking-dog
) else (
    echo ❌ Błąd podczas importowania
)
pause
EOF

# Skrypt uruchomieniowy z importu
cat > "${OUTPUT_DIR}/quick-start.sh" << 'EOF'
#!/bin/bash
# Szybkie uruchomienie z obrazu

echo "🚀 Barking Dog API - Szybkie uruchomienie"

# Znajdź obraz
IMAGE=$(docker images --format "table {{.Repository}}:{{.Tag}}" | grep barking-dog-api | head -n1)

if [ -z "$IMAGE" ]; then
    echo "❌ Nie znaleziono obrazu barking-dog-api"
    echo "Zaimportuj najpierw obraz używając import-linux-mac.sh"
    exit 1
fi

echo "📦 Używam obrazu: $IMAGE"

# Zatrzymaj istniejący kontener
docker stop barking-dog-container 2>/dev/null || true
docker rm barking-dog-container 2>/dev/null || true

# Uruchom nowy kontener
docker run -d \
    --name barking-dog-container \
    -p 8000:8000 \
    -v "$(pwd)/../app/sounds:/app/app/sounds" \
    "$IMAGE"

if [ $? -eq 0 ]; then
    echo "✅ Kontener uruchomiony pomyślnie!"
    echo "📡 API dostępne na: http://localhost:8000"
    echo "🔊 Test: curl -X GET http://localhost:8000/warn"
    echo "📋 Logi: docker logs -f barking-dog-container"
else
    echo "❌ Błąd podczas uruchamiania kontenera"
fi
EOF

# Uczyń skrypty wykonywalnymi
chmod +x "${OUTPUT_DIR}/import-linux-mac.sh"
chmod +x "${OUTPUT_DIR}/quick-start.sh"

# Stwórz README dla obrazów
cat > "${OUTPUT_DIR}/README.md" << 'EOF'
# 🐳 Barking Dog API - Docker Images

Gotowe obrazy Docker dla różnych platform.

## 📦 Dostępne obrazy

Sprawdź plik `images-info.txt` dla listy dostępnych obrazów.

## 🚀 Szybkie uruchomienie

### Linux/macOS:
```bash
# Importuj obraz
./import-linux-mac.sh barkingDog-img-linux-amd64.tar.gz

# Uruchom
./quick-start.sh
```

### Windows:
```bat
REM Importuj obraz (wymaga 7-zip)
import-windows.bat barkingDog-img-linux-amd64.tar.gz

REM Uruchom ręcznie
docker run -d -p 8000:8000 barking-dog-api:latest-linux-amd64
```

### Raspberry Pi:
```bash
# Importuj obraz ARM
./import-linux-mac.sh barkingDog-img-raspberry-pi.tar.gz

# Uruchom
./quick-start.sh
```

### iOS/Apple Silicon:
```bash
# Importuj obraz ARM
./import-linux-mac.sh barkingDog-img-ios-arm64.tar.gz

# Uruchom
./quick-start.sh
```

## 🔧 Ręczne uruchomienie

```bash
# Importuj
gunzip -c barkingDog-img-PLATFORMA.tar.gz | docker load

# Uruchom
docker run -d -p 8000:8000 barking-dog-api:latest-PLATFORMA

# Test
curl -X GET http://localhost:8000/warn
```

## 📁 Struktura

- `*.tar.gz` - Obrazy Docker
- `import-*.sh/bat` - Skrypty importu
- `quick-start.sh` - Szybkie uruchomienie
- `images-info.txt` - Informacje o obrazach
EOF

# Podsumowanie
echo -e "\n${GREEN}🎉 Proces zakończony!${NC}"
echo -e "${BLUE}📁 Pliki utworzone w katalogu: ${OUTPUT_DIR}${NC}"
echo ""
echo -e "${YELLOW}📋 Dostępne pliki:${NC}"
ls -la "$OUTPUT_DIR/"
echo ""
echo -e "${GREEN}✅ Gotowe obrazy Docker można przenieść na inne maszyny!${NC}"
echo -e "${BLUE}ℹ️  Instrukcje użycia w: ${OUTPUT_DIR}/README.md${NC}"

# Wyświetl informacje o obrazach
if [ -f "${OUTPUT_DIR}/images-info.txt" ]; then
    echo -e "\n${BLUE}📊 Utworzone obrazy:${NC}"
    cat "${OUTPUT_DIR}/images-info.txt"
fi

echo -e "\n${GREEN}🚀 Teraz możesz przenieść katalog ${OUTPUT_DIR} na inne maszyny!${NC}"