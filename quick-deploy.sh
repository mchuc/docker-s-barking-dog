#!/bin/bash
# quick-deploy.sh - Szybkie wdrożenie na nowej maszynie
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

set -e

echo "🚀 Barking Dog API - Szybkie wdrożenie"
echo "====================================="

# Sprawdź czy jesteśmy w odpowiednim katalogu
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Nie znaleziono docker-compose.yml"
    echo "Upewnij się, że jesteś w katalogu docker-s-barking-dog"
    exit 1
fi

# Menu wyboru
echo "Wybierz opcję wdrożenia:"
echo "1) Docker Compose (zbuduj lokalnie)"
echo "2) Użyj gotowego obrazu (jeśli dostępny)"
echo "3) Utwórz obrazy dla różnych platform"
echo "4) Test istniejącego API"

read -p "Opcja (1-4): " choice

case $choice in
    1)
        echo "🔨 Budowanie i uruchamianie Docker Compose..."
        docker-compose down 2>/dev/null || true
        docker-compose build
        docker-compose up -d
        ;;
    2)
        echo "📦 Szukanie dostępnych obrazów..."
        if [ -d "docker-images" ]; then
            echo "Dostępne obrazy:"
            ls -la docker-images/*.tar.gz 2>/dev/null || echo "Brak obrazów .tar.gz"
            
            # Auto-detect platform
            ARCH=$(uname -m)
            case $ARCH in
                x86_64|amd64)
                    IMAGE_FILE="docker-images/barkingDog-img-linux-amd64.tar.gz"
                    ;;
                aarch64|arm64)
                    IMAGE_FILE="docker-images/barkingDog-img-raspberry-pi.tar.gz"
                    ;;
                armv7l)
                    IMAGE_FILE="docker-images/barkingDog-img-raspberry-pi-armv7.tar.gz"
                    ;;
                *)
                    IMAGE_FILE="docker-images/barkingDog-img-native.tar.gz"
                    ;;
            esac
            
            if [ -f "$IMAGE_FILE" ]; then
                echo "📥 Importowanie obrazu dla $ARCH: $IMAGE_FILE"
                gunzip -c "$IMAGE_FILE" | docker load
                
                # Uruchom kontener
                docker stop barking-dog-quick 2>/dev/null || true
                docker rm barking-dog-quick 2>/dev/null || true
                docker run -d \
                    --name barking-dog-quick \
                    -p 8000:8000 \
                    -v "$(pwd)/app/sounds:/app/app/sounds" \
                    $(docker images --format "{{.Repository}}:{{.Tag}}" | grep barking-dog-api | head -n1)
            else
                echo "❌ Nie znaleziono obrazu dla architektury $ARCH"
                echo "Użyj opcji 3 aby utworzyć obrazy"
                exit 1
            fi
        else
            echo "❌ Katalog docker-images nie istnieje"
            echo "Użyj opcji 3 aby utworzyć obrazy"
            exit 1
        fi
        ;;
    3)
        echo "🏭 Tworzenie obrazów Docker..."
        chmod +x docker-image.sh
        ./docker-image.sh
        ;;
    4)
        echo "🧪 Testowanie API..."
        chmod +x test-api.sh
        ./test-api.sh
        ;;
    *)
        echo "❌ Nieprawidłowa opcja"
        exit 1
        ;;
esac

# Sprawdź czy API jest dostępne
echo ""
echo "⏳ Czekam na uruchomienie API..."
for i in {1..30}; do
    if curl -s http://localhost:8000/ >/dev/null 2>&1; then
        echo "✅ API jest dostępne!"
        break
    fi
    sleep 2
    echo -n "."
done

echo ""
echo "🎉 Wdrożenie zakończone!"
echo "📡 API dostępne na: http://localhost:8000"
echo "📖 Dokumentacja API: http://localhost:8000/docs"
echo "🔊 Test endpoint: curl -X POST http://localhost:8000/warn"
echo ""
echo "📋 Przydatne komendy:"
echo "  docker ps                    # Zobacz działające kontenery"
echo "  docker logs -f CONTAINER_ID  # Zobacz logi"
echo "  ./test-api.sh                # Uruchom testy"