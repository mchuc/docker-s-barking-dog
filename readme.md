# 🐕 Barking Dog API - Docker Edition

API do odtwarzania losowych dźwięków szczekania psów z kontrolą współbieżności. Kompatybilny z Windows, Linux, macOS i Docker.

(C)2025  Marcin Chuć ORCID: 0000-0002-8430-9763

## 🚀 Szybkie uruchomienie

### Opcja 1: Docker Compose (Zalecane)

```bash
# Linux/macOS
./run-docker.sh

# Windows
run-docker.bat
```

### Opcja 2: Obrazy gotowe do przenoszenia

```bash
# Utwórz obrazy dla różnych platform
./docker-image.sh          # Linux/macOS
# lub
.\docker-image.ps1         # Windows PowerShell

# Obrazy zostaną zapisane w katalogu ./docker-images/
# Pliki: barkingDog-img-PLATFORMA.tar.gz
```

### Opcja 3: Manualnie

```bash
# Zbuduj obraz
docker-compose build

# Uruchom
docker-compose up -d

# Sprawdź logi
docker-compose logs -f
```

## � Przenoszenie na inne maszyny

### Tworzenie przenośnych obrazów

```bash
# Linux/macOS
chmod +x docker-image.sh
./docker-image.sh

# Windows PowerShell  
.\docker-image.ps1
```

**Utworzone pliki:**
- `barkingDog-img-linux-amd64.tar.gz` - Linux/Windows Docker Desktop
- `barkingDog-img-raspberry-pi.tar.gz` - Raspberry Pi 4+
- `barkingDog-img-raspberry-pi-armv7.tar.gz` - Starsze Raspberry Pi
- `barkingDog-img-ios.tar.gz` - iOS/iPhone/iPad z Docker (Apple Silicon)

### Importowanie na docelowej maszynie

```bash
# Linux/macOS
gunzip -c barkingDog-img-linux-amd64.tar.gz | docker load
docker run -d -p 8000:8000 barking-dog-api:latest-linux-amd64

# Windows (wymaga 7-zip)
7z x barkingDog-img-linux-amd64.tar.gz -so | docker load
docker run -d -p 8000:8000 barking-dog-api:latest-linux-amd64

# Raspberry Pi
gunzip -c barkingDog-img-raspberry-pi.tar.gz | docker load
docker run -d -p 8000:8000 barking-dog-api:latest-raspberry-pi

# iOS/Apple Silicon (wymaga Docker Desktop na iOS lub aplikacji Docker)
gunzip -c barkingDog-img-ios.tar.gz | docker load
docker run -d -p 8000:8000 barking-dog-api:latest-ios
```

## 🔧 Konfiguracja

### 🔊 `/warn` (POST)
Główny endpoint ostrzegawczy:
- **Pierwsze wywołanie**: Losuje i odtwarza dźwięk → `status: "PLAYING"`
- **Podczas odtwarzania**: Zwraca `status: "BUSY"`
- **Po zakończeniu**: Ponownie dostępny do losowania

```bash
curl -X POST http://localhost:8000/warn
```

## Optymalizator dźwięku

Projekt zawiera narzędzie do ujednolicenia tonu szczekania psa. Możesz dodać nowe pliki audio do katalogu `sounds/originals` i uruchomić optymalizator, aby dopasować wysokość dźwięku wszystkich nagrań do pliku wzorcowego.

### Użycie

1. Dodaj pliki MP3 z nagraniami szczekania do katalogu `sounds/originals/`
2. Uruchom optymalizator:
   ```bash
   cd app/tools
   python optimize.py
   ```
3. Zoptymalizowane pliki zostaną zapisane w katalogu `sounds/optimized/` z sufiksem `_aligned.wav`

Optymalizator automatycznie:
- Wykrywa podstawową częstotliwość (F0) każdego nagrania
- Dopasowuje wysokość dźwięku do pliku wzorcowego (`dog-bark-type-03-293293.mp3`)
- Normalizuje głośność wszystkich plików
- Zapisuje wyniki w formacie WAV 16-bit

### Wymagania

Upewnij się, że masz zainstalowane:
- `rubberband` (via Homebrew: `brew install rubberband`)
- Wymagane biblioteki Python (patrz `requirements.txt`)

## 🖥️ Kompatybilność platform

### Windows
- ✅ winsound (natywny)
- ✅ pygame (fallback)  
- ✅ systemowy odtwarzacz

### Linux  
- ✅ pygame (główny)
- ✅ alsa (aplay)
- ✅ pulseaudio (paplay)
- ✅ mpg123, ffplay

### macOS
- ✅ pygame (główny)
- ✅ afplay (systemowy)

### Docker
- ✅ pygame (zoptymalizowany)
- ✅ Linux audio stack
- ✅ Bezgłowy tryb (headless)

## 🐳 Docker - Audio bez ekranu

Aplikacja działa w trybie headless - nie wymaga ekranu ani klawiatury. Audio jest odtwarzane przez pygame i Linux audio tools.

## 📁 Struktura projektu

```
docker-s-barking-dog/
├── Dockerfile              # Definicja kontenera
├── docker-compose.yml      # Orchestracja
├── run-docker.sh          # Skrypt uruchomieniowy Linux/macOS
├── run-docker.bat         # Skrypt uruchomieniowy Windows
├── docker-image.sh        # Tworzenie obrazów (Linux/macOS)
├── docker-image.ps1       # Tworzenie obrazów (Windows)
├── quick-deploy.sh        # Szybkie wdrożenie z menu
├── test-api.sh           # Skrypt testowy API
├── README.md             # Ta dokumentacja
├── docker-images/        # Katalog z gotowymi obrazami (po uruchomieniu docker-image.sh)
│   ├── barkingDog-img-*.tar.gz
│   ├── import-*.sh
│   └── README.md
└── app/
    ├── start.py           # Główna aplikacja FastAPI
    ├── models.py          # Modele Pydantic
    ├── installation/
    │   └── requirements.txt
    └── sounds/
        └── optimized/     # Pliki audio (WAV/MP3)
```

## 🚀 Scenariusze użycia

### Szybkie wdrożenie na nowej maszynie
```bash
# Sklonuj repozytorium
git clone https://github.com/mchuc/docker-s-barking-dog.git
cd docker-s-barking-dog

# Użyj interaktywnego skryptu
chmod +x quick-deploy.sh
./quick-deploy.sh
```

### Przenoszenie bez dostępu do internetu
```bash
# Na maszynie źródłowej (z internetem)
./docker-image.sh

# Skopiuj katalog docker-images/ na docelową maszynę
# Na docelowej maszynie (bez internetu)
cd docker-images
./import-linux-mac.sh barkingDog-img-linux-amd64.tar.gz
./quick-start.sh
```

## 📝 Licencja

Apache License 2.0 - otwarte oprogramowanie z pełną swobodą użycia komercyjnego! 🎉

Szczegóły w pliku [LICENSE](LICENSE)

## 👨‍💻 Autor

(C)2025 Marcin Chuć ORCID: 0000-0002-8430-9763
