#!/bin/bash

echo "=== Instalacja pakietów dla Raspberry Pi Zero - Debian ==="

# Aktualizacja repozytoriów
sudo apt-get update

# Instalacja pakietów systemowych i audio
echo "Instalowanie pakietów audio i Bluetooth..."
sudo apt-get install -y \
    alsa-utils \
    pulseaudio \
    pulseaudio-module-bluetooth \
    pulseaudio-utils \
    bluez \
    bluez-tools \
    bluetooth \
    pi-bluetooth \
    rubberband-cli \
    librubberband-dev \
    python3-numpy \
    python3-scipy \
    python3-audioread \
    python3-soundfile \
    python3-fastapi \
    python3-uvicorn \
    python3-pygame \
    python3-requests \
    librubberband-dev \
    ffmpeg
    #pip install --upgrade pip setuptools wheel
# pip install --no-build-isolation --prefer-binary librosa pyrubberband

# Instalacja odtwarzaczy mediów
echo "Instalowanie odtwarzaczy mediów..."
sudo apt-get install -y \
    mpg123 \
    sox \
    libsox-fmt-all

# Instalacja zależności kompilacji (potrzebne dla Python)
echo "Instalowanie narzędzi deweloperskich..."
sudo apt-get install -y \
    build-essential \
    gcc \
    pkg-config \
    libasound2-dev \
    libpulse-dev

# Instalacja Python i pip (jeśli nie są zainstalowane)
echo "Sprawdzanie Python..."
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-dev

# Dodanie użytkownika do grup audio i bluetooth
echo "Dodawanie użytkownika $USER i root do grup audio i bluetooth..."
sudo usermod -a -G audio,bluetooth,pulse-access $USER
sudo usermod -a -G audio,bluetooth,pulse-access root

# Sprawdzenie grup użytkownika
echo "Aktualne grupy użytkownika $USER:"
groups $USER

# Konfiguracja PulseAudio dla autologowania
echo "Konfigurowanie PulseAudio..."
mkdir -p ~/.config/pulse
if [ ! -f ~/.config/pulse/client.conf ]; then
    echo "autospawn = yes" > ~/.config/pulse/client.conf
fi

# Włączenie usług Bluetooth
echo "Włączanie usług Bluetooth..."
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

# Restart usługi PulseAudio
echo "Restartowanie PulseAudio..."
pulseaudio -k 2>/dev/null
pulseaudio --start 2>/dev/null

echo ""
echo "=== Instalacja zakończona ==="
echo "WAŻNE: Wyloguj się i zaloguj ponownie, aby zmiany w grupach zostały zastosowane."
echo ""
echo "Użyteczne komendy:"
echo "  bluetoothctl          - zarządzanie Bluetooth"
echo "  pactl list sinks      - lista urządzeń audio"
echo "  speaker-test -t wav   - test głośnika" 

#######TEST PULSE AUDIO
#uruchomineie pulse audio na starcie systemu
# odblokowanie pulse audio dla każego usera
# sudo pulseaudio --system --disallow-exit --disallow-module-loading=0
# echo "systemctl --user enable pulseaudio.service"
# echo "systemctl --user start pulseaudio.service"

#sprawdzenie, czy mam pulseaudio: 
# pactl info
#sprawdz, czy masz urzadzenia audio
# pactl list sinks


####
####
#jako główne wyjście audio ustaw głośnik bluetooth
# pactl set-default-sink bluez_sink.XX_XX_XX_XX_

#pactl list short sink-inputs

# test dźwięku
#speaker-test -t wav
#speaker-test -D bluez_sink.XX_XX_XX_XX_XX_X -t wav
#########
#utrwalamy zmiany
#sudo nano /etc/pulse/default.pa
### dodaj na końcu Auto Bluetooth sink setup
#load-module module-bluetooth-discover


#... i przechodzimy do serwera

#po skopiowaniu app

python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r ./app/installation/requirements.txt --progress-bar=on --verbose