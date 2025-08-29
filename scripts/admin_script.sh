#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# admin_tool.sh — CyberSec del 1
# Kjøring:
#   sudo ./admin_tool.sh

SCRIPT_NAME=$(basename "$0")

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "[$SCRIPT_NAME] Du må kjøre som root (bruk: sudo $0)" >&2
    exit 1
  fi
}

show_menu() {
  clear
  echo "========================"
  echo "   Admin Tool - Meny"
  echo "========================"
  echo "1) Opprett bruker"
  echo "2) Slett bruker"
  echo "3) Endre gruppe / lag ny gruppe"
  echo "4) Endre autentisering"
  echo "5) Start/stop webserver"
  echo "6) Vis brukere og siste login"
  echo "7) Avslutt"
  echo "========================"
}

create_user(){
 read -rp "Brukernavn: " username
 read -rp "Epost adresse: " email_addr
 read -rp "Passord: " password
 echo 

 #Selve opprettelsen av bruker og hjemmemappen
 useradd -m -s /bin/bash "$username"

 #Sette opp passord 
 echo "$username:$password" | chpasswd

 echo "Bruker $username er blitt opprettet. "
 echo "Epost blir sendt til $email_addr " 

}


delete_user(){
 read -rp "Skriv inn ønsket bruker du vil slette: " username
 if [[ "$username" == "root" ]]; then 
   echo "Root-brukeren kan ikke slettes!" 
   return 
 fi 

 current_user=${SUDO_USER:-$USER} #SUDO_USER utgjør brukeren som kjører scriptet
 if [["$username" == "$current_user"]]; then 
   echo "Nåverende bruker kan ikke slettes!"
   return
 fi 

 # &> betyr at både stdout og stderr skal sendes til /dev/null
 # /dev/null er et slags sort hull slik at informasjon som sendes dit
 # forsvinner. Det for å unngå å se feilmeldinger per nå
 if id "$username" &>/dev/null; then
   userdel -r "$username"
   echo "Bruker $username har blitt slettet!"
 else 
   echo "Gitt bruker eksisterer ikke!"
   echo "Trykk enter for å gå tilbake til hovedmeny og prøv på nytt"
 fi 
}




main() {
  require_root

  while true; do
    show_menu
    read -rp "Velg et alternativ [1-7]: " choice
    case $choice in
      1)
	echo "Oppretter bruker --->"
	create_user
        read -rp "Trykk enter for å fortsette..." dummy
        ;;
      2)
        echo "Sletter bruker --->"
	delete_user
        read -rp "Trykk enter for å fortsette..." dummy
        ;;
      3)
        echo "[TODO] Endre gruppe / lag ny gruppe"
        read -rp "Trykk enter for å fortsette..." dummy
        ;;
      4)
        echo "[TODO] Endre autentisering"
        read -rp "Trykk enter for å fortsette..." dummy
        ;;
      5)
        echo "[TODO] Start/stop webserver"
        read -rp "Trykk enter for å fortsette..." dummy
        ;;
      6)
        echo "[TODO] Vis brukere og siste login"
        read -rp "Trykk enter for å fortsette..." dummy
        ;;
      7)
        echo "Avslutter..."
        exit 0
        ;;
      *)
        echo "Ugyldig valg!"
        sleep 1
        ;;
    esac
  done
}

main "$@"

