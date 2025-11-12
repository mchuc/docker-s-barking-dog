# 🐕 Barking Dog API - Docker Edition

API do odtwarzania losowych dźwięków szczekania psów z kontrolą współbieżności. Kompatybilny z Windows, Linux, macOS i Docker.

(C)2025 Marcin Chuć ORCID: 0000-0002-8430-9763

## 🚀 Szybkie uruchomienie

### Opcja 1: Szybkie uruchomienie Python (ZALECANE - pełne audio)

```bash
# Jeden plik - uruchom i już! (Windows/Linux/macOS/iOS)
python3 run-uvicorn-debug.py
```

**Dlaczego to najlepsze rozwiązanie:**

- ✅ **Pełne audio na wszystkich platformach** (Windows, Linux, macOS, iOS)
- ✅ **Brak ograniczeń Docker** - natywny dostęp do systemu audio
- ✅ **Automatyczne sprawdzanie zależności**
- ✅ **Hot-reload podczas developmentu**
- ✅ **Szybkie uruchomienie** - jeden plik, jedna komenda
- ✅ **Na iOS/macOS: rzeczywisty dźwięk** (w przeciwieństwie do Docker)

### Opcja 2: Środowisko wirtualne (.venv)

```bash
# Utwórz i aktywuj środowisko
python3 -m venv .venv

# Linux/macOS
source .venv/bin/activate
# Windows (PowerShell)
.\.venv\Scripts\Activate.ps1
# Windows (CMD)
.\.venv\Scripts\activate.bat

# Zainstaluj zależności
pip install -r app/installation/requirements.txt

# Uruchom serwer (z hot-reload)
uvicorn app.start:app --host 0.0.0.0 --port 8000 --reload
```

### Opcja 3: Docker z audio (Linux) / symulacja (iOS/macOS)

```bash
# Automatyczna konfiguracja audio dla Twojej platformy
./run-docker-with-audio.sh
```

### Opcja 4: Docker Compose (podstawowy)

```bash
# Linux/macOS/Windows (Docker Desktop)
docker compose up --build
```

### Opcja 5: Obrazy gotowe do przenoszenia

```bash
# Utwórz obrazy dla różnych platform
./docker-image.sh          # Linux/macOS
# lub
.\docker-image.ps1         # Windows PowerShell

# Obrazy zostaną zapisane w katalogu ./docker-images/
# Pliki: barkingDog-img-PLATFORMA.tar.gz
```

## 🔊 Audio na różnych platformach

### ⭐ Uruchomienie natywne Python (`run-uvicorn-debug.py`)

**Windows:** ✅ Pełne audio (winsound + pygame)
**Linux:** ✅ Pełne audio (pygame + ALSA/PulseAudio)  
**macOS:** ✅ Pełne audio (afplay + pygame)
**iOS:** ✅ **Pełne audio natywne** (afplay + pygame)

### 🐳 Docker

**Windows:** ⚠️ Symulacja audio (dummy driver)
**Linux:** ✅ Pełne audio (PulseAudio/ALSA w kontenerze)
**macOS:** ⚠️ Symulacja audio (ograniczenie Docker Desktop)
**iOS:** ⚠️ Symulacja audio (ograniczenie Docker Desktop)

### 💡 Wniosek dla iOS/macOS

**Dla pełnego audio na iOS/macOS użyj:**

```bash
python3 run-uvicorn-debug.py    # ← PEŁNE AUDIO
```

**Zamiast Docker, który ma ograniczenia:**

```bash
./run-docker-with-audio.sh      # ← tylko symulacja na iOS/macOS
```

## 🔊 Audio w Docker

### ⚠️ Ważne - Audio na iOS/macOS Docker

**iOS/macOS + Docker Desktop = Brak fizycznego audio**

- Jest to normalne zachowanie i ograniczenie platformy
- Aplikacja działa prawidłowo (API, timery, logika)
- Audio jest "symulowane" - brak fizycznego dźwięku
- To NIE jest błąd aplikacji

### Alternatywy dla iOS z prawdziwym audio

```bash
# Opcja 1: Uruchomienie natywne (zalecane dla iOS)
python3 run-uvicorn-debug.py    # Pełne audio przez macOS/iOS

# Opcja 2: Docker z komunikatami informacyjnymi (symulacja)
./run-docker-with-audio.sh
```

### Problem z kartą dźwiękową

Docker domyślnie nie ma dostępu do karty dźwiękowej hosta. Oto rozwiązania:

#### Opcja 1: Natywne uruchomienie (najlepsze dla iOS/macOS)

```bash
# Pełne audio na wszystkich platformach
python3 run-uvicorn-debug.py
```

#### Opcja 2: Docker z audio (Linux)

```bash
# Linux/macOS z konfiguracją audio
chmod +x run-docker-with-audio.sh
./run-docker-with-audio.sh

# Windows
run-docker-with-audio.bat
```

#### Opcja 3: Ręczna konfiguracja

**Linux (PulseAudio):**

```bash
docker run -d -p 8000:8000 \
  -v /run/user/$(id -u)/pulse:/run/user/1000/pulse:ro \
  --device /dev/snd:/dev/snd \
  -e PULSE_SERVER=unix:/run/user/1000/pulse/native \
  -e SDL_AUDIODRIVER=pulse,alsa,dummy \
  barking-dog-api
```

**macOS/iOS (Docker Desktop - dummy audio):**

```bash
docker run -d -p 8000:8000 \
  -e SDL_AUDIODRIVER=dummy \
  -e PYGAME_HIDE_SUPPORT_PROMPT=1 \
  barking-dog-api
```

**Windows (Docker Desktop):**

```powershell
docker run -d -p 8000:8000 `
  -e SDL_AUDIODRIVER=dummy `
  -e PYGAME_HIDE_SUPPORT_PROMPT=1 `
  barking-dog-api
```

### Tryby audio

1. **Pełne audio** (Natywne uruchomienie) - rzeczywisty dźwięk na wszystkich platformach
2. **Linux Docker** (PulseAudio/ALSA) - rzeczywisty dźwięk w kontenerze
3. **iOS/macOS Docker** (Dummy) - symulacja bez dźwięku
4. **Windows Docker** (Dummy) - symulacja bez dźwięku

### Sprawdzenie audio

```bash
# Test endpoint (działa zawsze)
curl -X GET http://localhost:8000/warn

# Sprawdź typ audio w logach
docker logs barking-dog-api | grep -E "(Audio|SYMULACJA|🔇)"
```

## ❓ FAQ: audio na iOS

- Czy w iOS mam dźwięk?
  - Tak, przy uruchomieniu NATYWNYM (FastAPI/uvicorn): dźwięk działa normalnie.
  - Nie (symulacja), w Docker Desktop na iOS/macOS: to ograniczenie platformy. Użyj opcji natywnej: `python3 run-uvicorn-debug.py`.

## 🔧 Lokalne uruchomienie (bez Docker)

### Dlaczego lokalne na iOS/macOS?

- ✅ **Pełne wsparcie audio** na wszystkich platformach
- ✅ Brak ograniczeń Docker Desktop
- ✅ Natywny dostęp do systemu audio
- ✅ Hot-reload podczas developmentu
- ✅ Lepsze performance

### Wymagania

- Python 3.8+
- pip/pip3

### Automatyczne uruchomienie

```bash
# Opcja 1: Szybkie (automatyczne sprawdzenia)
python3 run-uvicorn-debug.py

# Opcja 2: Z środowiskiem wirtualnym (.venv)
python3 -m venv .venv
source .venv/bin/activate    # Windows: .\.venv\Scripts\Activate.ps1
pip install -r app/installation/requirements.txt
uvicorn app.start:app --host 0.0.0.0 --port 8000 --reload
```

### Ręczne uruchomienie

```bash
# Utwórz środowisko wirtualne (opcjonalne)
python3 -m venv .venv

# Aktywuj (Linux/macOS)
source .venv/bin/activate

# Aktywuj (Windows)
.venv\Scripts\activate

# Instaluj zależności
pip install -r app/installation/requirements.txt

# Uruchom serwer
cd app
uvicorn start:app --host 0.0.0.0 --port 8000 --reload
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

## 🔧 Troubleshooting audio (uruchomienie natywne)

Jeśli przy uruchomieniu natywnym widzisz komunikat:
„Audio: używam pygame (dummy - SYMULACJA bez dźwięku)”, wykonaj:

```bash
# 1) Sprawdź czy środowisko nie wymusza trybu dummy
echo "SDL_AUDIODRIVER=$SDL_AUDIODRIVER"

# 2) Usuń wymuszenie (jeśli ustawione na 'dummy')
unset SDL_AUDIODRIVER

# 3) Przetestuj systemowy odtwarzacz (macOS):
afplay app/sounds/optimized/<jakiś_plik>.wav

# 4) Uruchom ponownie serwer:
python3 run-uvicorn-debug.py
```

Uwagi:

- Na macOS natywnie pygame użyje CoreAudio – nie ustawiaj SDL_AUDIODRIVER.
- Tryb „dummy” powinien włączać się tylko w kontenerze (iOS/Docker) lub jako awaryjny fallback, gdy inicjalizacja audio się nie powiedzie.
- Jeśli nadal brak dźwięku, upewnij się, że system nie jest wyciszony i że plik audio odtwarza się przez `afplay`.

#projekt PiZero:
w raspberry pi zero/ 2w postępuj wg plików

> uruchom pizero.sh
> połącz się z głośnikiem - zobacz pizero.connect.sh
> przekopiuj serisy : .service i je odblokuj
> przekopiuj pizero.bluetooth.sh

restart maliny
