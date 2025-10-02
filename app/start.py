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

from fastapi import FastAPI
import os
import librosa
from pathlib import Path
from typing import Dict, List, Any, Union
from itertools import chain
import time
import threading
import asyncio

# Import modeli Pydantic
from .models import (
    SoundsDatabase, 
    SoundInfo, 
    AudioStatus, 
    AudioType,
    SoundResponse,
    SoundsDatabaseResponse,
    RefreshResponse,
    ErrorResponse,
    RandomSoundResponse,
    RandomSoundErrorResponse,
    WarnResponse,
    WarnErrorResponse,
    PlaybackState
)

# Windows audio support
try:
    import winsound
    WINSOUND_AVAILABLE = True
except ImportError:
    WINSOUND_AVAILABLE = False

# Cross-platform audio support
try:
    import pygame
    PYGAME_AVAILABLE = True
except ImportError:
    PYGAME_AVAILABLE = False

try:
    import subprocess
    import sys
    SUBPROCESS_AVAILABLE = True
except ImportError:
    SUBPROCESS_AVAILABLE = False

# Detect audio capabilities
AUDIO_AVAILABLE = WINSOUND_AVAILABLE or PYGAME_AVAILABLE or SUBPROCESS_AVAILABLE

# Ścieżka do katalogu z dźwiękami
SOUNDS_DIR = Path(__file__).parent / "sounds" / "optimized"

# Globalna baza danych dźwięków (obiekt Pydantic)
sounds_database = SoundsDatabase()

# Globalny stan odtwarzania audio (obiekt Pydantic)
playback_state = PlaybackState()

def create_sounds_table():
    """
    Tworzy globalną bazę danych z informacjami o dźwiękach.
    Używa modeli Pydantic dla typowej struktury danych.
    Funkcja do wywoływania przy starcie lub czasowo
    Obsługuje pliki WAV i MP3
    """
    global sounds_database
    sounds_database.clear()  # Wyczyść poprzednie dane
    
    print("=" * 60)
    print("TABELA DZWIEKOW - ANALIZA PLIKOW AUDIO")
    print("=" * 60)
    
    # Utwórz katalog jeśli nie istnieje
    if not SOUNDS_DIR.exists():
        print(f"Katalog {SOUNDS_DIR} nie istnieje - tworze...")
        try:
            SOUNDS_DIR.mkdir(parents=True, exist_ok=True)
            print(f"Katalog {SOUNDS_DIR} zostal utworzony")
        except Exception as e:
            print(f"BLAD podczas tworzenia katalogu: {e}")
            return sounds_database
    
    # Pobierz wszystkie pliki audio z katalogu (WAV i MP3) - ignorując wielkość liter
    patterns = ["*.[Ww][Aa][Vv]", "*.[Mm][Pp]3"]
    audio_files = list(chain.from_iterable(SOUNDS_DIR.glob(pattern) for pattern in patterns))
    
    if not audio_files:
        print("Nie znaleziono plikow audio (.wav/.mp3) w katalogu")
        print(f"Katalog: {SOUNDS_DIR}")
        print("Aby zobaczyc tabele, dodaj pliki audio do tego katalogu")
        return sounds_database
    
    print(f"Znaleziono {len(audio_files)} plikow audio")
    print("\n" + "-" * 90)
    print(f"{'NAZWA PLIKU':<40} {'TYP':<6} {'DLUGOSC [s]':<12} {'SAMPLE RATE':<12} {'ROZMIAR':<15}")
    print("-" * 90)
    
    for audio_file in sorted(audio_files):
        filename = audio_file.name  # Klucz - nazwa pliku z rozszerzeniem
        
        try:
            # Wczytaj plik audio i pobierz długość
            y, sr = librosa.load(str(audio_file), sr=None)
            duration = len(y) / sr
            file_size_bytes = audio_file.stat().st_size
            file_type = AudioType.WAV if audio_file.suffix.upper() == ".WAV" else AudioType.MP3
            
            # Utwórz obiekt SoundInfo (Pydantic model)
            sound_info = SoundInfo(
                length=round(duration, 2),
                sample_rate=int(sr),
                size_bytes=file_size_bytes,
                type=file_type,
                path=str(audio_file),
                status=AudioStatus.OK
            )
            
            # Dodaj do globalnej bazy danych
            sounds_database.add_sound(filename, sound_info)
            
            # Wyświetl wiersz tabeli z formatowanym rozmiarem
            formatted_size = sound_info.get_formatted_size()
            print(f"{filename:<40} {file_type.value:<6} {duration:<12.2f} {sr:<12} {formatted_size:<15}")
            
        except Exception as e:
            # Utwórz obiekt SoundInfo dla błędu
            file_type = AudioType.WAV if audio_file.suffix.upper() == ".WAV" else AudioType.MP3
            error_info = SoundInfo(
                length=None,
                sample_rate=None,
                size_bytes=None,
                type=file_type,
                path=str(audio_file),
                status=AudioStatus.ERROR,
                error=str(e)
            )
            
            # Dodaj błędny plik do bazy danych
            sounds_database.add_sound(filename, error_info)
            print(f"{filename:<40} {file_type.value:<6} {'BLAD':<12} {'-':<12} {'-':<15}")
    
    print("-" * 90)
    
    # Pobierz statystyki z modelu Pydantic
    stats = sounds_database.get_stats()
    
    print(f"PODSUMOWANIE:")
    print(f"   Laczna dlugosc: {stats['total_duration']:.2f} sekund ({stats['duration_minutes']:.1f} minut)")
    print(f"   Laczny rozmiar: {stats['total_size_formatted']} ({stats['total_size_bytes']} bajtow)")
    print(f"   Liczba plikow: {stats['total_files']} (WAV: {stats['wav_count']}, MP3: {stats['mp3_count']})")
    print("=" * 60)
    
    return sounds_database

def play_audio_file(file_path: str, duration: float):
    """
    Odtwarza plik audio w tle używając dostępnego systemu audio.
    Kompatybilny z Windows, Linux, macOS i Docker.
    Aktualizuje globalny stan odtwarzania (Pydantic model).
    """
    global playback_state
    
    try:
        # Ustaw stan odtwarzania używając metody Pydantic
        playback_state.start_playback(Path(file_path).name, duration)
        
        print(f"Rozpoczynam odtwarzanie: {playback_state.filename} (długość: {duration:.2f}s)")
        
        # Wykryj platformę
        is_ios_docker = os.environ.get('PLATFORM_HINT') == 'ios' or \
                       (sys.platform.startswith('linux') and
                        os.environ.get('SDL_AUDIODRIVER', '').startswith('dummy'))

        # Wybór metody odtwarzania w zależności od dostępności
        audio_played = False
        
        # Próba 1: Windows winsound (najlepsze dla Windows)
        if WINSOUND_AVAILABLE and not audio_played:
            try:
                winsound.PlaySound(str(file_path), winsound.SND_FILENAME | winsound.SND_ASYNC)
                audio_played = True
                print("Audio: używam winsound (Windows)")
            except Exception as e:
                print(f"winsound nie zadziałał: {e}")
        
        # Próba 2: pygame (multiplatformowy)
        if PYGAME_AVAILABLE and not audio_played:
            try:
                # Specjalna konfiguracja dla iOS/Docker
                if is_ios_docker:
                    os.environ['SDL_AUDIODRIVER'] = 'dummy'
                    print("Audio: iOS/Docker wykryty - używam trybu symulacji")
                else:
                    os.environ.setdefault('SDL_AUDIODRIVER', 'pulse,alsa,dummy')

                # Inicjalizacja pygame z fallback do dummy
                pygame.mixer.pre_init(frequency=22050, size=-16, channels=2, buffer=512)
                pygame.mixer.init()

                # Sprawdź czy audio rzeczywiście działa
                if pygame.mixer.get_init():
                    pygame.mixer.music.load(str(file_path))
                    pygame.mixer.music.play()
                    audio_played = True
                    audio_driver = os.environ.get('SDL_AUDIODRIVER', 'unknown')

                    if is_ios_docker or 'dummy' in audio_driver:
                        print("Audio: używam pygame (dummy - SYMULACJA bez dźwięku)")
                        print("       Na iOS/Docker fizyczny dźwięk nie jest dostępny")
                        print("       Aplikacja działa normalnie, ale bez audio output")
                    else:
                        print(f"Audio: używam pygame ({audio_driver})")
                else:
                    print("pygame: audio nie został zainicjalizowany")

            except Exception as e:
                print(f"pygame nie zadziałał: {e}")
                # Próba z wymuszonym dummy driver
                try:
                    os.environ['SDL_AUDIODRIVER'] = 'dummy'
                    pygame.mixer.quit()
                    pygame.mixer.init()
                    if pygame.mixer.get_init():
                        pygame.mixer.music.load(str(file_path))
                        pygame.mixer.music.play()
                        audio_played = True
                        print("Audio: używam pygame (dummy - SYMULACJA)")
                        print("       Brak fizycznego dźwięku, ale aplikacja działa")
                except Exception as e2:
                    print(f"pygame dummy również nie zadziałał: {e2}")

        # Próba 3: systemowe odtwarzacze (fallback)
        if SUBPROCESS_AVAILABLE and not audio_played and not is_ios_docker:
            try:
                if sys.platform.startswith('win'):
                    subprocess.run(['start', '', str(file_path)], shell=True, check=False)
                    audio_played = True
                    print("Audio: używam systemowy (Windows)")
                elif sys.platform.startswith('darwin'):
                    subprocess.run(['afplay', str(file_path)], check=False)
                    audio_played = True
                    print("Audio: używam afplay (macOS)")
                elif sys.platform.startswith('linux'):
                    # Próbuj różne odtwarzacze Linux (pomiń w iOS/Docker)
                    for player in ['aplay', 'paplay', 'mpg123', 'ffplay']:
                        try:
                            result = subprocess.run([player, str(file_path)],
                                                   capture_output=True,
                                                   timeout=1,
                                                   check=False)
                            if result.returncode == 0:
                                audio_played = True
                                print(f"Audio: używam {player} (Linux)")
                                break
                        except (subprocess.TimeoutExpired, FileNotFoundError):
                            continue
                else:
                    print("Audio: nieznany system operacyjny")
            except Exception as e:
                print(f"systemowy odtwarzacz nie zadziałał: {e}")
        
        # Komunikat specjalny dla iOS
        if not audio_played or is_ios_docker:
            if is_ios_docker:
                print("🔇 AUDIO iOS/DOCKER INFO:")
                print("   ├─ Tryb symulacji - brak fizycznego dźwięku")
                print("   ├─ Jest to normalne zachowanie na iOS/Docker")
                print("   ├─ API działa prawidłowo, timery są zachowane")
                print("   └─ Dla rzeczywistego audio użyj wersji natywnej")
            else:
                print("Audio: brak dostępnych odtwarzaczy - tylko symulacja")
                print("       (aplikacja działa normalnie, ale bez fizycznego dźwięku)")

        # Czekaj przez czas trwania pliku
        time.sleep(duration)
        
    except Exception as e:
        print(f"Błąd podczas odtwarzania pliku {file_path}: {e}")
    finally:
        # Wyczyść stan odtwarzania używając metody Pydantic
        playback_state.stop_playback()

        if is_ios_docker:
            print(f"🔇 Zakończono symulację odtwarzania (iOS/Docker)")
        else:
            print(f"Zakończono odtwarzanie")

def start_audio_playback(file_path: str, duration: float):
    """
    Uruchamia odtwarzanie audio w osobnym wątku.
    """
    thread = threading.Thread(target=play_audio_file, args=(file_path, duration), daemon=True)
    thread.start()

def is_audio_playing() -> bool:
    """
    Sprawdza czy aktualnie odtwarzany jest dźwięk.
    Używa metody Pydantic model do sprawdzenia stanu.
    """
    global playback_state
    return playback_state.is_currently_playing()

app = FastAPI(title="Barking's Dog API", version="1.0.0")

# Tworzenie globalnej bazy danych dźwięków przy starcie
sounds_database = create_sounds_table()

@app.get("/")
async def read_root():
    return {"message": "Barking's Dog API!"}

@app.get("/sounds/refresh", response_model=RefreshResponse)
async def refresh_sounds_table():
    """
    Endpoint do odświeżenia globalnej bazy danych dźwięków czasowo
    """
    global sounds_database
    sounds_database = create_sounds_table()
    stats = sounds_database.get_stats()
    
    return RefreshResponse(
        message="Globalna baza dzwiekow zostala odswiezona",
        liczba_plikow=stats["total_files"],
        sounds_database=sounds_database.get_all_sounds(),
        stats=stats
    )

@app.get("/sounds/database", response_model=SoundsDatabaseResponse)
async def get_sounds_database():
    """
    Endpoint zwracający całą globalną bazę danych dźwięków
    """
    stats = sounds_database.get_stats()
    
    return SoundsDatabaseResponse(
        sounds_database=sounds_database.get_all_sounds(),
        liczba_plikow=stats["total_files"],
        stats=stats
    )

@app.get("/sounds/{filename}", response_model=Union[SoundResponse, ErrorResponse])
async def get_sound_info(filename: str):
    """
    Endpoint zwracający informacje o konkretnym pliku dźwiękowym
    """
    sound_info = sounds_database.get_sound(filename)
    
    if sound_info:
        return SoundResponse(
            filename=filename,
            info=sound_info
        )
    else:
        return ErrorResponse(
            error=f"Plik {filename} nie zostal znaleziony w bazie danych",
            available_files=list(sounds_database.get_all_sounds().keys())
        )

@app.get("/sounds/random/get", response_model=Union[RandomSoundResponse, RandomSoundErrorResponse])
async def get_random_sound():
    """
    Endpoint zwracający losowy dźwięk (różny od ostatnio wylosowanego)
    """
    previous_sound = sounds_database.last_random_sound
    random_result = sounds_database.get_random_sound()
    
    if random_result:
        filename, sound_info = random_result
        stats = sounds_database.get_stats()
        
        return RandomSoundResponse(
            filename=filename,
            info=sound_info,
            previous_sound=previous_sound,
            total_available=stats["valid_sounds_count"]
        )
    else:
        stats = sounds_database.get_stats()
        return RandomSoundErrorResponse(
            error="Brak dostepnych dzwiekow do wylosowania",
            total_files=stats["total_files"],
            valid_files=stats["valid_sounds_count"]
        )

@app.post("/sounds/random/reset")
async def reset_random_history():
    """
    Endpoint resetujący historię losowania dźwięków
    """
    sounds_database.reset_random_history()
    return {
        "message": "Historia losowania zostala zresetowana",
        "last_random_sound": None
    }

@app.get("/warn")
async def warn_endpoint():
    """
    Endpoint ostrzegawczy - losuje i odtwarza dźwięk jeśli żaden nie jest aktualnie odtwarzany.
    Jeśli dźwięk jest już odtwarzany, zwraca status BUSY.
    """
    # Sprawdź czy aktualnie odtwarzamy dźwięk używając Pydantic model
    if is_audio_playing():
        return WarnResponse(
            status="BUSY",
            filename=playback_state.filename,
            info=None,
            message=f"Aktualnie odtwarzany jest plik: {playback_state.filename}. Spróbuj ponownie za chwilę.",
            estimated_end_time=playback_state.end_time
        )
    
    # Jeśli nic nie odtwarzamy, wylosuj nowy dźwięk
    random_result = sounds_database.get_random_sound()
    
    if not random_result:
        # Brak dostępnych dźwięków
        stats = sounds_database.get_stats()
        return WarnErrorResponse(
            status="ERROR",
            error="Brak dostępnych dźwięków do odtworzenia",
            total_files=stats["total_files"],
            valid_files=stats["valid_sounds_count"]
        )
    
    filename, sound_info = random_result
    
    # Uruchom rzeczywiste odtwarzanie w tle
    start_audio_playback(sound_info.path, sound_info.length)
    
    print(f"Rozpoczynam odtwarzanie: {filename} (długość: {sound_info.length:.2f}s)")
    
    return WarnResponse(
        status="PLAYING",
        filename=filename,
        info=sound_info,
        message=f"Rozpoczynam odtwarzanie pliku: {filename} (długość: {sound_info.length:.2f}s)",
        estimated_end_time=time.time() + sound_info.length
    )
