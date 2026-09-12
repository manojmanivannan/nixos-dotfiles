#!/usr/bin/env bash

#echo "Running backup_shortcut"
#/home/manoj/.scripts/backup_shortcut.sh
#No need to run backup script, everything is taken care with stow

echo "RSYNC: Checking if Password file contains password"
if [ ! -s "$HOME/.config/rsync/dxp_pass" ]; then
  echo "RSYNC: Password file is empty or does not exist."
  echo "Please create the password file with the correct password (hint: NamePoliceSymbol)."
  exit 1
fi

if [ ! -d "$HOME/Apps" ]; then
  echo "RSYNC: Source directory $HOME/Apps does not exist. Please check the source directory."
  echo "Recommend to pull Apps directory from NAS to Local:"
  echo
  echo "Do you want to pull the Apps directory from NAS to Local? (y/n)"
  read -r answer
  if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    echo "Pulling Apps directory from NAS to Local..."
    rsync -avz --timeout=600 --no-o --no-g --no-p --chmod=ugo=rwX \
      --password-file="$HOME/.config/rsync/dxp_pass" \
      rsync://manoj@dxp2800-nas-mm.local:/home/Backup/linux-backup/Apps \
      "$HOME/"
    echo "Pull completed."
  else
    echo "Pull operation canceled."
  fi
  exit 1
fi

# Rsync service to backup to NAS
echo "RSYNC: Running rsync"
rsync -avz --timeout=600 --delete --delete-excluded --no-o --no-g --no-p --chmod=ugo=rwX\
  --password-file="$HOME/.config/rsync/dxp_pass" \
  --exclude-from="$HOME/.config/rsync/ignore" \
  "$HOME/Apps" \
  rsync://manoj@dxp2800-nas-mm.local:/home/Backup/linux-backup