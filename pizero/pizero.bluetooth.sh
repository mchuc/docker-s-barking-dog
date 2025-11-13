#!/bin/bash
#save as sudo nano /usr/local/bin/pizero.bluetooth.sh
#sudo chmod +x /usr/local/bin/pizero.bluetooth.sh
#touch /var/log/bt-autoconnect.log
#chmod 666 /var/log/bt-autoconnect.log



#####*******************************************
DEVICE_MAC="00:42:79:FE:FE:XX"   # <- tu wpisz adres MAC swojego głośnika
#####*******************************************

export PULSE_SERVER=unix:/var/run/pulse/native
LOGFILE="/var/log/bt-autoconnect.log"


echo "$(date): [INFO] Start bt-autoconnect" >> "$LOGFILE"

# --- FUNKCJE ---

connect_device() {
    echo "$(date): [INFO] Próba połączenia z $DEVICE_MAC" >> "$LOGFILE"
    # Łączenie przez bluetoothctl
    bluetoothctl << EOF
power on
agent on
default-agent
connect $DEVICE_MAC
EOF

    # Poczekaj chwilę, aż PulseAudio wykryje głośnik
    sleep 5

    # Zamiana dwukropków na podkreślenia
    MAC_UNDERSCORE=${DEVICE_MAC//:/_}
    PA_SINK_ID="bluez_sink.${MAC_UNDERSCORE}.a2dp_sink"
    PA_CARD_ID="bluez_card.${MAC_UNDERSCORE}"

    # Upewnij się, że moduł Bluetooth w PulseAudio jest załadowany
    pactl list modules short | grep -q "module-bluetooth-discover" || {
        echo "$(date): [INFO] Ładuję module-bluetooth-discover" >> "$LOGFILE"
        pactl load-module module-bluetooth-discover
        sleep 2
    }

    # Ustaw profil A2DP
    if pactl list cards short | grep -q "$PA_CARD_ID"; then
        pactl set-card-profile "$PA_CARD_ID" a2dp_sink
        echo "$(date): [INFO] Ustawiono profil A2DP dla $PA_CARD_ID" >> "$LOGFILE"
    fi

    # Ustaw domyślne wyjście audio
    if pactl list short sinks | grep -q "$PA_SINK_ID"; then
        pactl set-default-sink "$PA_SINK_ID"
        echo "$(date): [INFO] Ustawiono domyślny sink: $PA_SINK_ID" >> "$LOGFILE"
    else
        echo "$(date): [WARN] Nie znaleziono sinka $PA_SINK_ID – może jeszcze się nie pojawił?" >> "$LOGFILE"
    fi
}

# --- GŁÓWNA PĘTLA ---
while true; do
    # Upewnij się, że adapter działa
    rfkill unblock bluetooth
    hciconfig hci0 up 2>/dev/null

    # Sprawdź, czy urządzenie jest połączone
    STATUS=$(bluetoothctl info "$DEVICE_MAC" | grep "Connected: yes")

    if [ -z "$STATUS" ]; then
        echo "$(date): [WARN] Głośnik niepołączony – próba połączenia..." >> "$LOGFILE"
        connect_device
    else
        echo "$(date): [OK] Głośnik połączony" >> "$LOGFILE"
    fi

    sleep 30
done

