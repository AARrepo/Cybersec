#!/usr/bin/env bash
# Juster disse variablene:
target="https://filsett.local/login.php"   # eller "http://127.0.0.1/filsett/login.php"
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
