from fastapi import FastAPI
import os
import librosa
from pathlib import Path
from typing import Dict, List, Any, Union
from itertools import chain

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
    RandomSoundErrorResponse
)

# Ścieżka do katalogu z dźwiękami
SOUNDS_DIR = Path(__file__).parent / "sounds" / "optimized"

# Globalna baza danych dźwięków (obiekt Pydantic)
sounds_database = SoundsDatabase()

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
