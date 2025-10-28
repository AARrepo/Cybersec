#!/usr/bin/env bash

target="http://<SERVER_IP>/login.php"   # eller "http://filsett/login.php" som server-navn
tries=30                                   # antall POSTs
delay=0.5                                  # sekunder mellom hver request

echo "Sender $tries requests mot $target (delay $delay s)"
for i in $(seq 1 $tries); do
  # unik passorddata slik at det ikke caches
  curl -k -s -o /dev/null -X POST -d "username=test&password=p$i" "$target" &
  sleep "$delay"
done
wait
echo "Ferdig."
