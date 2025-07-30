#!/bin/bash
set -e  # Stoppe le script si une commande échoue

# Dossiers à créer dans la RAM pour les enregistrements
BASE_DIR="/tmp/record"
PLAYLIST_DIR="$BASE_DIR/playlist"

# Création des dossiers si inexistants
mkdir -p "$PLAYLIST_DIR"

# Donner les droits complets (lecture, écriture, exécution) à tous les utilisateurs
chmod -R 777 "$BASE_DIR"

echo "Dossiers créés et permissions définies dans $BASE_DIR"

# noatime et nodiratime évite de réécrire la date d’accès à chaque lecture pour prevenir les écritures
mount -o remount,rw,noatime,nodiratime /opt

