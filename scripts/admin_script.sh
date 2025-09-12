#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# — CyberSec del 1

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
  echo "7) Vis grupper"
  echo "8) Avslutt"
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
 echo "Bruker med $username er blitt opprettet!" | mail -s "Ny bruker opprettet" "$email_addr"
 
}


delete_user(){
 read -rp "Skriv inn ønsket bruker du vil slette: " username
 if [[ "$username" == "root" ]]; then 
   echo "Root-brukeren kan ikke slettes!" 
   return 
 fi 

 current_user=${SUDO_USER:-$USER} #SUDO_USER utgjør brukeren som kjører scriptet
 if [[ "$username" == "$current_user" ]]; then 
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

group_manager(){
 echo "Du får nå følgende valg: "
 echo "1) Opprette en ny gruppe" 
 echo "2) Legge til en bruker i en eksisterende gruppe"
 echo "3) Endre tilhørigheten til en bruker i en gruppe"
 read -rp "Velg: " choice 

 case $choice in
   1)
     read -rp "Skriv inn gruppenavn: " group_name
     if getent group "$group_name" > /dev/null 2>&1; then
       echo "Gruppe $group_name finnes allerede!"
     else 
       groupadd "$group_name"
       echo "Gruppe $group_name har blitt opprettet"
     fi
     ;;
   2) 
     read -rp "Brukernavn: " username
     read -rp "Gruppenavn: " group_name
     if ! id "$username" &>/dev/null; then 
       echo "Brukeren $username finnes ikke!"
       return 
     fi
     if ! getent group "$group_name" > /dev/null 2>&1; then 
       echo "Gruppen $group_name finnes ikke! Enten har du skrevet feil eller så må den opprettes." 
       return 
     fi
     usermod -aG "$group_name" "$username"
     echo "Bruker $username er lagt til i $group_name"
     ;;
   3) 
     read -rp "Brukernavn: " username
     read -rp "Ny primærgruppe: " group_name
     if ! id "$username" &>/dev/null; then 
       echo "Brukeren $username finnes ikke!"
       return 
     fi
     if ! getent group "$group_name" > /dev/null 2>&1; then
       echo "Gruppen $group_name finnes ikke! Enten har du skrevet feil eller så må den opprettes."
       return 
     fi
     usermod -g "$group_name" "$username"
     echo "Primærgruppe for $username er nå $group_name" 
     ;;
   *)
     echo "Ugyldig valg!"
  esac
}

show_groups(){
  echo "========================"
  echo "   Grupper og brukere"
  echo "========================"
  # getent group henter alle grupper i /etc/group
  # cut -d: -f1,4 viser bare gruppenavn og brukermedlemmer
  getent group | cut -d: -f1,4 | while IFS=: read -r group users; do
    if [[ -n "$users" ]]; then
      echo "Gruppe: $group"
      echo "  Brukere: $users"
    else
      echo "Gruppe: $group"
      echo "  (ingen brukere)"
    fi
    echo
  done
}


change_authentication() {
  read -rp "Brukernavn du ønsker å endre autentisering for: " username

  if ! id "$username" &>/dev/null; then
    echo "Brukeren $username finnes ikke!"
    return
  fi

  echo "Setter opp OTP for $username..."
  echo "Følg instruksjonene i terminalen for å konfigurere Google Authenticator."

  # Kjører google-authenticator som brukeren (interaktivt første gang)
  # Går inn i brukeren sin shell og skriver inn kommandoen nedenfor
  su - "$username" -c "google-authenticator"

  # Loggfører at OTP er aktivert
  # Loggen vil ligge i var/log/ og dette ligger i rot katalogen ikke hjemmekatalogen
  log_file="/var/log/admin_tool_auth.log"
  echo "$(date '+%Y-%m-%d %H:%M:%S') : OTP aktivert for bruker $username" >> "$log_file"

  echo "OTP er nå aktivert for $username. Brukeren må bruke Authenticator-app ved neste innlogging."
}



#-------------------------------------
main() {
  require_root

  while true; do
    show_menu
    read -rp "Velg et alternativ [1-8]: " choice
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
        echo "Oppretter ny gruppe/endrer gruppe --->"
	group_manager
        read -rp "Trykk enter for å fortsette..." dummy
        ;;
      4)
        echo "Endrer autentisering ---> "
        change_authentication
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
	show_groups
	read -rp "Trykk enter for å fortsette..." dummy
	;;
      8)
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

