#!/bin/bash
# Skrypt uruchomieniowy z konfiguracją audio dla różnych platform

set -e

# Kolory
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🐕 Barking Dog API - Uruchomienie z audio${NC}"
echo "=================================================="

# Wykryj system operacyjny
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macOS"
    echo -e "${YELLOW}🍎 Wykryto macOS/iOS - Docker Desktop${NC}"
    AUDIO_FLAGS=""
    ENV_FLAGS="-e SDL_AUDIODRIVER=dummy -e PYGAME_HIDE_SUPPORT_PROMPT=1"

elif [[ "$OSTYPE" == "linux"* ]]; then
    PLATFORM="Linux"
    echo -e "${GREEN}🐧 Wykryto Linux - konfiguracja PulseAudio${NC}"

    # Sprawdź czy PulseAudio działa
    if pgrep -x "pulseaudio" > /dev/null; then
        echo -e "${GREEN}✅ PulseAudio uruchomiony${NC}"
        USER_ID=$(id -u)
        PULSE_PATH="/run/user/${USER_ID}/pulse"

        AUDIO_FLAGS="-v ${PULSE_PATH}:${PULSE_PATH}:ro --device /dev/snd:/dev/snd"
        ENV_FLAGS="-e PULSE_SERVER=unix:${PULSE_PATH}/native -e SDL_AUDIODRIVER=pulse,alsa,dummy"
    else
        echo -e "${YELLOW}⚠️  PulseAudio nie działa - używam ALSA${NC}"
        AUDIO_FLAGS="--device /dev/snd:/dev/snd"
        ENV_FLAGS="-e SDL_AUDIODRIVER=alsa,dummy"
    fi

else
    PLATFORM="Windows/Other"
    echo -e "${YELLOW}🪟 System nieznany - używam dummy audio${NC}"
    AUDIO_FLAGS=""
    ENV_FLAGS="-e SDL_AUDIODRIVER=dummy -e PYGAME_HIDE_SUPPORT_PROMPT=1"
fi

# Zatrzymaj istniejący kontener
echo -e "${BLUE}🔄 Zatrzymywanie istniejących kontenerów...${NC}"
docker stop barking-dog-api 2>/dev/null || true
docker rm barking-dog-api 2>/dev/null || true

# Zbuduj obraz
echo -e "${BLUE}🔨 Budowanie obrazu Docker...${NC}"
docker build -t barking-dog-api .

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Błąd podczas budowania obrazu${NC}"
    exit 1
fi

# Uruchom kontener z konfiguracją audio
echo -e "${BLUE}🚀 Uruchamianie kontenera z audio (${PLATFORM})...${NC}"

docker run -d \
    --name barking-dog-api \
    -p 8000:8000 \
    -v "$(pwd)/app/sounds:/app/app/sounds" \
    $AUDIO_FLAGS \
    $ENV_FLAGS \
    barking-dog-api

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Kontener uruchomiony pomyślnie!${NC}"
    echo ""
    echo -e "${BLUE}📡 API dostępne na: http://localhost:8000${NC}"
    echo -e "${BLUE}🔊 Test audio: curl -X GET http://localhost:8000/warn${NC}"
    echo -e "${BLUE}📋 Logi: docker logs -f barking-dog-api${NC}"
    echo ""

    if [[ "$PLATFORM" == "macOS" ]]; then
        echo -e "${YELLOW}ℹ️  Na macOS/iOS audio działa w trybie dummy (symulacja)${NC}"
        echo -e "${YELLOW}   Aplikacja będzie działać normalnie, ale bez fizycznego dźwięku${NC}"
    fi

    # Sprawdź status po 5 sekundach
    sleep 5
    if docker ps | grep -q barking-dog-api; then
        echo -e "${GREEN}✅ Kontener działa stabilnie${NC}"
    else
        echo -e "${RED}❌ Problem z kontenerem - sprawdź logi:${NC}"
        echo "docker logs barking-dog-api"
    fi

else
    echo -e "${RED}❌ Błąd podczas uruchamiania kontenera${NC}"
    exit 1
fi

