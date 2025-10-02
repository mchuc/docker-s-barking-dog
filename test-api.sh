#!/bin/bash
# Test API endpoints
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

# Test podstawowy
echo "📡 Test podstawowy..."
curl -s "$API_URL/" | jq .

echo -e "\n🔊 Test endpoint /warn (GET)..."
curl -s "$API_URL/warn" | jq .

echo -e "\n📊 Test bazy danych dźwięków..."
curl -s "$API_URL/sounds/database" | jq .

echo -e "\n🎲 Test losowego dźwięku..."
curl -s "$API_URL/sounds/random/get" | jq .

echo -e "\n✅ Testy zakończone"
