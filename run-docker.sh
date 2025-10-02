#!/bin/bash
# Uruchomienie dla Linux/macOS
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

echo "=== Barking Dog API - Uruchomienie Docker ==="

# Sprawdź czy Docker jest zainstalowany
if ! command -v docker &> /dev/null; then
    echo "❌ Docker nie jest zainstalowany. Zainstaluj Docker Desktop lub Docker Engine."
    exit 1
fi

# Sprawdź czy docker-compose jest dostępny
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose nie jest dostępny."
    exit 1
fi

echo "✅ Docker i Docker Compose są dostępne"

# Zbuduj i uruchom kontener
echo "🔨 Budowanie obrazu Docker..."
docker-compose build

if [ $? -eq 0 ]; then
    echo "✅ Obraz zbudowany pomyślnie"
    echo "🚀 Uruchamianie kontenera..."
    docker-compose up -d
    
    echo ""
    echo "🎉 Aplikacja uruchomiona!"
    echo "📡 API dostępne na: http://localhost:8000"
    echo "📖 Dokumentacja API: http://localhost:8000/docs"
    echo "🔊 Test endpoint: curl -X POST http://localhost:8000/warn"
    echo ""
    echo "📋 Przydatne komendy:"
    echo "  docker-compose logs -f      # Zobacz logi"
    echo "  docker-compose stop         # Zatrzymaj"
    echo "  docker-compose down         # Zatrzymaj i usuń kontener"
else
    echo "❌ Błąd podczas budowania obrazu"
    exit 1
fi