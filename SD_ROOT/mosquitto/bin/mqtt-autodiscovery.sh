#!/opt/wz_mini/bin/bash
set -euo pipefail

# === Fonctions utilitaires ===

error_exit() {
    echo "❌ Erreur: $1" >&2
    exit 1
}

check_command() {
    command -v "$1" >/dev/null 2>&1 || error_exit "La commande '$1' est introuvable."
}

# === Vérification des dépendances ===
check_command ip
check_command awk
check_command cut
check_command "$MOSQUITTO_PUB_BIN" || error_exit "mosquitto_pub non défini ou introuvable."

# === Chargement des fichiers de configuration ===
MASTER_CONFIG="/opt/wz_mini/wz_mini.conf"
MQTT_CONFIG="/media/mmc/mosquitto/mosquitto.conf"

[[ -f "$MASTER_CONFIG" ]] || error_exit "Fichier de config manquant: $MASTER_CONFIG"
[[ -f "$MQTT_CONFIG" ]] || error_exit "Fichier de config manquant: $MQTT_CONFIG"

# shellcheck disable=SC1090
source "$MASTER_CONFIG"
# shellcheck disable=SC1090
source "$MQTT_CONFIG"

# === Fonction de publication MQTT ===
mqtt_publish() {
    local topic="$1"
    local payload="$2"

    "$MOSQUITTO_PUB_BIN" \
        -h "$MQTT_BROKER_HOST" \
        -p "$MQTT_BROKER_PORT" \
        -u "$MQTT_USERNAME" \
        -P "$MQTT_PASSWORD" \
        -t "$topic" \
        ${MOSQUITTOPUBOPTS:-} ${MOSQUITTOOPTS:-} \
        -r -m "$payload" || error_exit "Échec de la publication MQTT sur le topic '$topic'"
}

# === Récupération IP et MAC ===
IP=$(ip addr show wlan0 | awk '/inet / {print $2}' | cut -d/ -f1) || error_exit "Impossible de récupérer l'adresse IP"
MAC=$(ip link show wlan0 | awk '/link\/ether/ {print $2}') || error_exit "Impossible de récupérer l'adresse MAC"

# === Construction du JSON de découverte ===
DEVICE_JSON=$(cat <<EOF
{
  "name": "${CUSTOM_HOSTNAME}",
  "mac": "${MAC}",
  "id": "WyzeV3",
  "ip": "${IP}"
}
EOF
)

# === Publication MQTT ===
TOPIC_BASE="${MQTT_WYZE_TOPIC}/${CUSTOM_HOSTNAME}"
mqtt_publish "${TOPIC_BASE}/discovery" "$DEVICE_JSON"
