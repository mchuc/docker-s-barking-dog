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

from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from enum import Enum
import random

class AudioStatus(str, Enum):
    """Status pliku audio"""
    OK = "ok"
    ERROR = "error"

class AudioType(str, Enum):
    """Typ pliku audio"""
    WAV = ".WAV"
    MP3 = ".MP3"

class SoundInfo(BaseModel):
    """Model informacji o pojedynczym pliku dźwiękowym"""
    length: Optional[float] = Field(None, description="Długość w sekundach")
    sample_rate: Optional[int] = Field(None, description="Częstotliwość próbkowania w Hz")
    size_bytes: Optional[int] = Field(None, description="Rozmiar pliku w bajtach")
    type: AudioType = Field(..., description="Typ pliku audio")
    path: str = Field(..., description="Ścieżka do pliku")
    status: AudioStatus = Field(..., description="Status pliku")
    error: Optional[str] = Field(None, description="Opis błędu jeśli status=error")
    
    def get_formatted_size(self) -> str:
        """Zwraca rozmiar pliku w naturalnej jednostce (B/KB/MB)"""
        if self.size_bytes is None:
            return "N/A"
        
        bytes_size = self.size_bytes
        
        if bytes_size < 1024:
            return f"{bytes_size} B"
        elif bytes_size < 1024 * 1024:
            kb_size = bytes_size / 1024
            return f"{kb_size:.1f} KB"
        else:
            mb_size = bytes_size / (1024 * 1024)
            return f"{mb_size:.2f} MB"
    
    def get_size_mb(self) -> float:
        """Zwraca rozmiar w MB (dla kompatybilności wstecznej)"""
        if self.size_bytes is None:
            return 0.0
        return self.size_bytes / (1024 * 1024)
    
    def get_size_kb(self) -> float:
        """Zwraca rozmiar w KB"""
        if self.size_bytes is None:
            return 0.0
        return self.size_bytes / 1024
    
    class Config:
        """Konfiguracja modelu"""
        use_enum_values = True
        json_encoders = {
            AudioStatus: lambda v: v.value,
            AudioType: lambda v: v.value
        }

class SoundsDatabase(BaseModel):
    """Model globalnej bazy danych dźwięków"""
    database: Dict[str, SoundInfo] = Field(default_factory=dict, description="Baza danych dźwięków")
    total_files: int = Field(0, description="Łączna liczba plików")
    total_duration: float = Field(0.0, description="Łączna długość w sekundach") 
    total_size_bytes: int = Field(0, description="Łączny rozmiar w bajtach")
    wav_count: int = Field(0, description="Liczba plików WAV")
    mp3_count: int = Field(0, description="Liczba plików MP3")
    last_random_sound: Optional[str] = Field(None, description="Ostatnio wylosowany dźwięk")
    
    def add_sound(self, filename: str, sound_info: SoundInfo) -> None:
        """Dodaj plik dźwiękowy do bazy danych"""
        self.database[filename] = sound_info
        self._update_stats()
    
    def remove_sound(self, filename: str) -> bool:
        """Usuń plik dźwiękowy z bazy danych"""
        if filename in self.database:
            del self.database[filename]
            self._update_stats()
            return True
        return False
    
    def get_sound(self, filename: str) -> Optional[SoundInfo]:
        """Pobierz informacje o pliku dźwiękowym"""
        return self.database.get(filename)
    
    def get_all_sounds(self) -> Dict[str, SoundInfo]:
        """Pobierz wszystkie pliki dźwiękowe"""
        return self.database
    
    def clear(self) -> None:
        """Wyczyść bazę danych"""
        self.database.clear()
        self.last_random_sound = None
        self._update_stats()
    
    def get_random_sound(self, max_attempts: int = 50) -> Optional[tuple[str, SoundInfo]]:
        """
        Pobierz losowy dźwięk, różny od ostatnio wylosowanego.
        
        Args:
            max_attempts: Maksymalna liczba prób losowania (zabezpieczenie przed nieskończoną pętlą)
            
        Returns:
            Tuple (nazwa_pliku, SoundInfo) lub None jeśli brak dostępnych plików
        """
        # Pobierz tylko pliki ze statusem OK
        valid_sounds = {
            filename: info for filename, info in self.database.items() 
            if info.status == AudioStatus.OK
        }
        
        if not valid_sounds:
            return None
        
        # Jeśli jest tylko jeden plik, zwróć go (nie ma z czym porównywać)
        if len(valid_sounds) == 1:
            filename = list(valid_sounds.keys())[0]
            self.last_random_sound = filename
            return (filename, valid_sounds[filename])
        
        # Jeśli nie ma ostatnio wylosowanego, losuj dowolny
        if self.last_random_sound is None:
            filename = random.choice(list(valid_sounds.keys()))
            self.last_random_sound = filename
            return (filename, valid_sounds[filename])
        
        # Losuj różny od ostatniego
        attempts = 0
        while attempts < max_attempts:
            filename = random.choice(list(valid_sounds.keys()))
            if filename != self.last_random_sound:
                self.last_random_sound = filename
                return (filename, valid_sounds[filename])
            attempts += 1
        
        # Jeśli po max_attempts nadal nie udało się wylosować różnego,
        # zwróć dowolny inny niż ostatni (awaryjne rozwiązanie)
        available_sounds = [f for f in valid_sounds.keys() if f != self.last_random_sound]
        if available_sounds:
            filename = random.choice(available_sounds)
            self.last_random_sound = filename
            return (filename, valid_sounds[filename])
        
        # Ostateczność - zwróć ostatnio wylosowany (nie powinno się zdarzyć)
        if self.last_random_sound in valid_sounds:
            return (self.last_random_sound, valid_sounds[self.last_random_sound])
        
        return None
    
    def reset_random_history(self) -> None:
        """Resetuj historię losowania - następny losowy dźwięk może być dowolny"""
        self.last_random_sound = None
    
    def get_formatted_total_size(self) -> str:
        """Zwraca łączny rozmiar w naturalnej jednostce"""
        if self.total_size_bytes < 1024:
            return f"{self.total_size_bytes} B"
        elif self.total_size_bytes < 1024 * 1024:
            kb_size = self.total_size_bytes / 1024
            return f"{kb_size:.1f} KB"
        else:
            mb_size = self.total_size_bytes / (1024 * 1024)
            return f"{mb_size:.2f} MB"
    
    def _update_stats(self) -> None:
        """Zaktualizuj statystyki bazy danych"""
        valid_files = [info for info in self.database.values() if info.status == AudioStatus.OK]
        
        self.total_files = len(self.database)
        self.total_duration = sum(info.length for info in valid_files if info.length is not None)
        self.total_size_bytes = sum(info.size_bytes for info in valid_files if info.size_bytes is not None)
        self.wav_count = len([info for info in self.database.values() if info.type == AudioType.WAV])
        self.mp3_count = len([info for info in self.database.values() if info.type == AudioType.MP3])
    
    def get_stats(self) -> Dict[str, Any]:
        """Pobierz statystyki bazy danych"""
        return {
            "total_files": self.total_files,
            "total_duration": self.total_duration,
            "total_size_bytes": self.total_size_bytes,
            "total_size_formatted": self.get_formatted_total_size(),
            "total_size_mb": round(self.total_size_bytes / (1024 * 1024), 2),
            "wav_count": self.wav_count,
            "mp3_count": self.mp3_count,
            "duration_minutes": round(self.total_duration / 60, 1) if self.total_duration else 0,
            "last_random_sound": self.last_random_sound,
            "valid_sounds_count": len([info for info in self.database.values() if info.status == AudioStatus.OK])
        }

class SoundResponse(BaseModel):
    """Model odpowiedzi API dla pojedynczego dźwięku"""
    filename: str = Field(..., description="Nazwa pliku")
    info: SoundInfo = Field(..., description="Informacje o pliku")

class SoundsDatabaseResponse(BaseModel):
    """Model odpowiedzi API dla całej bazy danych"""
    sounds_database: Dict[str, SoundInfo] = Field(..., description="Baza danych dźwięków")
    liczba_plikow: int = Field(..., description="Liczba plików")
    stats: Dict[str, Any] = Field(..., description="Statystyki bazy danych")

class RefreshResponse(BaseModel):
    """Model odpowiedzi API dla odświeżenia bazy danych"""
    message: str = Field(..., description="Wiadomość o statusie operacji")
    liczba_plikow: int = Field(..., description="Liczba plików")
    sounds_database: Dict[str, SoundInfo] = Field(..., description="Odświeżona baza danych")
    stats: Dict[str, Any] = Field(..., description="Statystyki bazy danych")

class ErrorResponse(BaseModel):
    """Model odpowiedzi błędu API"""
    error: str = Field(..., description="Opis błędu")
    available_files: Optional[list] = Field(None, description="Lista dostępnych plików")

class RandomSoundResponse(BaseModel):
    """Model odpowiedzi API dla losowego dźwięku"""
    filename: str = Field(..., description="Nazwa wylosowanego pliku")
    info: SoundInfo = Field(..., description="Informacje o wylosowanym pliku")
    previous_sound: Optional[str] = Field(None, description="Poprzednio wylosowany dźwięk")
    total_available: int = Field(..., description="Łączna liczba dostępnych dźwięków")

class RandomSoundErrorResponse(BaseModel):
    """Model odpowiedzi błędu dla losowego dźwięku"""
    error: str = Field(..., description="Opis błędu")
    total_files: int = Field(..., description="Łączna liczba plików w bazie")
    valid_files: int = Field(..., description="Liczba plików bez błędów")

class WarnResponse(BaseModel):
    """Model odpowiedzi API dla endpointu /warn"""
    status: str = Field(..., description="Status operacji: PLAYING lub BUSY")
    filename: Optional[str] = Field(None, description="Nazwa odtwarzanego pliku")
    info: Optional[SoundInfo] = Field(None, description="Informacje o odtwarzanym pliku")
    message: str = Field(..., description="Opis operacji")
    estimated_end_time: Optional[float] = Field(None, description="Przewidywany czas zakończenia odtwarzania (timestamp)")

class WarnErrorResponse(BaseModel):
    """Model odpowiedzi błędu dla endpointu /warn"""
    status: str = Field(..., description="Status błędu")
    error: str = Field(..., description="Opis błędu")
    total_files: int = Field(..., description="Łączna liczba plików w bazie")
    valid_files: int = Field(..., description="Liczba plików bez błędów")

class PlaybackState(BaseModel):
    """Model stanu odtwarzania audio"""
    is_playing: bool = Field(default=False, description="Czy aktualnie odtwarzany jest dźwięk")
    filename: Optional[str] = Field(default=None, description="Nazwa odtwarzanego pliku")
    start_time: Optional[float] = Field(default=None, description="Czas rozpoczęcia odtwarzania (timestamp)")
    duration: Optional[float] = Field(default=None, description="Długość pliku w sekundach")
    end_time: Optional[float] = Field(default=None, description="Przewidywany czas zakończenia (timestamp)")
    
    def start_playback(self, filename: str, duration: float) -> None:
        """Rozpocznij odtwarzanie nowego pliku"""
        import time
        self.is_playing = True
        self.filename = filename
        self.start_time = time.time()
        self.duration = duration
        self.end_time = time.time() + duration
    
    def stop_playback(self) -> None:
        """Zatrzymaj odtwarzanie i wyczyść stan"""
        self.is_playing = False
        self.filename = None
        self.start_time = None
        self.duration = None
        self.end_time = None
    
    def is_currently_playing(self) -> bool:
        """Sprawdź czy aktualnie odtwarzany jest dźwięk (uwzględniając czas)"""
        if not self.is_playing:
            return False
        
        # Sprawdź czy czas odtwarzania już minął
        import time
        if self.end_time and time.time() > self.end_time:
            # Czas minął - automatycznie wyczyść stan
            self.stop_playback()
            return False
        
        return True
    
    def get_remaining_time(self) -> Optional[float]:
        """Zwraca pozostały czas odtwarzania w sekundach"""
        if not self.is_currently_playing() or not self.end_time:
            return None
        
        import time
        remaining = self.end_time - time.time()
        return max(0, remaining)