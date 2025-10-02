#!/bin/bash
# Test script dla API
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

API_URL="http://localhost:8000"

echo "🧪 Testowanie Barking Dog API"
echo "=============================="

echo "1. 🏥 Test healthcheck..."
curl -s $API_URL/ | jq '.' || echo "❌ API niedostępne"

echo -e "\n2. 📋 Test bazy dźwięków..."
curl -s $API_URL/sounds/database | jq '.liczba_plikow' || echo "❌ Błąd bazy dźwięków"

echo -e "\n3. 🔊 Test pierwszego wywołania /warn..."
RESPONSE1=$(curl -s -X POST $API_URL/warn)
echo $RESPONSE1 | jq '.'
STATUS1=$(echo $RESPONSE1 | jq -r '.status')

if [ "$STATUS1" = "PLAYING" ]; then
    echo "✅ Pierwszy test PASSED - status: PLAYING"
    
    echo -e "\n4. 🔄 Test drugiego wywołania /warn (powinien być BUSY)..."
    RESPONSE2=$(curl -s -X POST $API_URL/warn)
    echo $RESPONSE2 | jq '.'
    STATUS2=$(echo $RESPONSE2 | jq -r '.status')
    
    if [ "$STATUS2" = "BUSY" ]; then
        echo "✅ Drugi test PASSED - status: BUSY"
        echo "🎉 Wszystkie testy przeszły pomyślnie!"
    else
        echo "❌ Drugi test FAILED - oczekiwano BUSY, otrzymano: $STATUS2"
    fi
else
    echo "❌ Pierwszy test FAILED - oczekiwano PLAYING, otrzymano: $STATUS1"
fi

echo -e "\n5. 🔄 Reset historii losowania..."
curl -s -X POST $API_URL/sounds/random/reset | jq '.'

echo -e "\n🏁 Test zakończony"