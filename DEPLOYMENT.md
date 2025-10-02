# 🐕 Barking Dog API - Instrukcja wdrożenia

## ⚡ Szybki start (1 minuta)

### Windows:
```powershell
# Krok 1: Uruchom Docker Desktop
# Krok 2: Otwórz PowerShell w katalogu projektu
.\run-docker.bat

# Test:
curl -X POST http://localhost:8000/warn
```

### Linux/macOS:
```bash
# Krok 1: Upewnij się że Docker jest uruchomiony
# Krok 2: Uruchom skrypt
chmod +x run-docker.sh
./run-docker.sh

# Test:
curl -X POST http://localhost:8000/warn
```

## 📦 Tworzenie przenośnych obrazów

### Dla administratorów IT:
```bash
# Utwórz obrazy dla wszystkich platform
./docker-image.sh

# Udostępnij katalog docker-images/ zespołowi
zip -r barking-dog-images.zip docker-images/
```

### Dla użytkowników końcowych:
```bash
# Rozpakuj otrzymane obrazy
unzip barking-dog-images.zip

# Importuj i uruchom
cd docker-images
./import-linux-mac.sh barkingDog-img-linux-amd64.tar.gz
./quick-start.sh
```

## 🎯 Przypadki użycia

### 1. System ostrzegawczy w biurze
```bash
# Integracja z systemem bezpieczeństwa
curl -X POST http://barking-dog-server:8000/warn
```

### 2. Raspberry Pi w domu
```bash
# Importuj obraz ARM
./import-linux-mac.sh barkingDog-img-raspberry-pi.tar.gz

# Uruchom z auto-restart
docker run -d --restart=unless-stopped -p 8000:8000 barking-dog-api:latest-raspberry-pi
```

### 3. Serwer produkcyjny
```bash
# Docker Compose z monitorowaniem
docker-compose up -d
docker-compose logs -f
```

## 🔧 Troubleshooting

### Problem: Audio nie działa w Docker
```bash
# Sprawdź logi
docker logs CONTAINER_ID

# Powinny być komunikaty typu:
# "Audio: używam pygame (multiplatformowy)"
# "Rozpoczynam odtwarzanie: plik.wav"
```

### Problem: Port zajęty
```bash
# Znajdź proces na porcie 8000
netstat -tlnp | grep 8000  # Linux
netstat -ano | findstr 8000  # Windows

# Zatrzymaj stary kontener
docker stop $(docker ps -q --filter "publish=8000")
```

### Problem: Brak dźwięków
```bash
# Sprawdź katalog sounds
ls -la app/sounds/optimized/

# Odśwież bazę dźwięków
curl -X POST http://localhost:8000/sounds/refresh
```

## 📞 Wsparcie

1. Sprawdź logi: `docker logs CONTAINER_NAME`
2. Przetestuj API: `curl http://localhost:8000/`
3. Uruchom test suite: `./test-api.sh`

---
**Autor:** Marcin Chuć  
**Licencja:** Apache 2.0  
**Repozytorium:** https://github.com/mchuc/docker-s-barking-dog