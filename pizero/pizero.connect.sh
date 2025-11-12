#sprwadz, czy masz oblokowany bluetooth
rfkill list all

# odblokuj bluetooth, jesli jest zablokowany
sudo rfkill unblock bluetooth

##uruchom interface
sudo hciconfig hci0 up

#sprawdz, czy interfejs jest uruchomiony
hciconfig

#uruchom narzedzie do parowania
bluetoothctl
echo "Wpisz nastepujace komendy w bluetoothctl:"
echo "  power on"
echo "  agent on"
echo "  default-agent"
echo "  scan on"
echo "Po znalezieniu urzadzenia wpisz:"
echo "  pair XX:XX:XX:XX:XX:XX"
echo "  trust XX:XX:XX:XX:XX:XX"
echo "  connect XX:XX:XX:XX:XX:XX"
echo "Zamknij bluetoothctl wpisujac 'exit'" 