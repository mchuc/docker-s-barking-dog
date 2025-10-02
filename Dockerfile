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

# Użyj oficjalnego obrazu Python jako bazowego
FROM python:3.12-slim

# Ustaw zmienne środowiskowe
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Instaluj systemowe zależności dla audio
RUN apt-get update && apt-get install -y \
    # Audio dependencies
    alsa-utils \
    pulseaudio \
    pulseaudio-utils \
    # Media players
    mpg123 \
    ffmpeg \
    # Build dependencies
    gcc \
    pkg-config \
    libasound2-dev \
    # Optional: for pygame
    libsdl2-dev \
    libsdl2-mixer-2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Utwórz użytkownika non-root dla bezpieczeństwa
RUN useradd --create-home --shell /bin/bash app

# Ustaw katalog roboczy
WORKDIR /app

# Skopiuj pliki requirements
COPY app/installation/requirements.txt .

# Instaluj zależności Python
RUN pip install --no-cache-dir -r requirements.txt

# Instaluj dodatkowe zależności audio dla Docker
RUN pip install --no-cache-dir pygame

# Skopiuj kod aplikacji
COPY app/ ./app/

# Zmień właściciela plików na użytkownika app
RUN chown -R app:app /app

# Przełącz na użytkownika non-root
USER app

# Eksponuj port
EXPOSE 8000

# Utwórz katalog na dźwięki (może być montowany jako volume)
RUN mkdir -p /app/app/sounds/optimized

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# Uruchom aplikację
CMD ["python", "-m", "uvicorn", "app.start:app", "--host", "0.0.0.0", "--port", "8000"]