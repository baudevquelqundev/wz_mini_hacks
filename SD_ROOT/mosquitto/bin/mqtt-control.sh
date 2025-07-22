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
check_command awk
check_command cut
check_command aplay
check_command "${MOSQUITTO_PUB_BIN:-mosquitto_pub}"
check_command "${MOSQUITTO_SUB_BIN:-mosquitto_sub}"

# === Chargement des fichiers de configuration ===
MASTER_CONFIG="/opt/wz_mini/wz_mini.conf"
ICAMERA_CONFIG="/configs/.user_config"
MQTT_CONFIG="/media/mmc/mosquitto/mosquitto.conf"

[[ -f "$MASTER_CONFIG" ]] || error_exit "Fichier manquant : $MASTER_CONFIG"
[[ -f "$MQTT_CONFIG" ]] || error_exit "Fichier manquant : $MQTT_CONFIG"

# shellcheck disable=SC1090
source "$MASTER_CONFIG"
# shellcheck disable=SC1090
source "$MQTT_CONFIG"

TOPIC_BASE="${MQTT_WYZE_TOPIC}/${CUSTOM_HOSTNAME}"

# === Fonction de publication MQTT ===
mqtt_publish() {
    local topic="$1"
    local payload="$2"

    "$MOSQUITTO_PUB_BIN" \
        -h "$MQTT_BROKER_HOST" \
        -p "$MQTT_BROKER_PORT" \
        -u "$MQTT_USERNAME" \
        -P "$MQTT_PASSWORD" \
        -t "${TOPIC_BASE}${topic}" \
        ${MOSQUITTOPUBOPTS:-} ${MOSQUITTOOPTS:-} \
        -m "$payload" || error_exit "Échec de publication sur ${topic}"
}

# === Démarrage de l'abonnement MQTT ===
"$MOSQUITTO_SUB_BIN" -v \
    -h "$MQTT_BROKER_HOST" \
    -p "$MQTT_BROKER_PORT" \
    -u "$MQTT_USERNAME" \
    -P "$MQTT_PASSWORD" \
    -t "${TOPIC_BASE}/#" \
    ${MOSQUITTOOPTS:-} \
    --will-topic "${TOPIC_BASE}/disconnected" \
| while read -r line; do

    case "$line" in

        "${TOPIC_BASE}/status "*)
            mqtt_publish "/connected" ""
        ;;

        "${TOPIC_BASE}/leds/red/set ON")
            echo '0' > /sys/devices/virtual/gpio/gpio38/value || error_exit "Erreur allumage LED rouge"
        ;;

        "${TOPIC_BASE}/leds/red/set OFF")
            echo '1' > /sys/devices/virtual/gpio/gpio38/value || error_exit "Erreur extinction LED rouge"
        ;;

        "${TOPIC_BASE}/leds/blue/set ON")
            echo '0' > /sys/devices/virtual/gpio/gpio39/value || error_exit "Erreur allumage LED bleue"
        ;;

        "${TOPIC_BASE}/leds/blue/set OFF")
            echo '1' > /sys/devices/virtual/gpio/gpio39/value || error_exit "Erreur extinction LED bleue"
        ;;

        "${TOPIC_BASE}/play "*)
            AUDIOFILE=$(echo "$line" | awk '{print $2}')
            VOLUME=$(echo "$line" | awk '{print $3}')

            [[ -z "$AUDIOFILE" || -z "$VOLUME" ]] && {
                echo "⚠️  Ligne /play invalide: '$line'" >&2
                continue
            }

            # Clamp volume entre 0 et 100 si nécessaire
            VOLUME="${VOLUME:-50}"
            if ! [[ "$VOLUME" =~ ^[0-9]+$ ]] || [ "$VOLUME" -lt 0 ] || [ "$VOLUME" -gt 100 ]; then
                echo "⚠️  Volume invalide : $VOLUME" >&2
                continue
            fi

            aplay "$AUDIOFILE" || error_exit "Échec de lecture audio : $AUDIOFILE"
        ;;

        *)
            echo "ℹ️  Message MQTT non pris en charge : $line" >&2
        ;;

    esac
done
