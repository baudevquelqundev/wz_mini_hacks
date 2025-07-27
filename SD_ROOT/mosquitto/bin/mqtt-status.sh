#!/opt/wz_mini/bin/bash
set -euo pipefail

# === Fonctions utilitaires ===
error_exit() {
    echo "❌ Erreur : $1" >&2
    exit 1
}

check_command() {
    command -v "$1" >/dev/null 2>&1 || error_exit "Commande introuvable : $1"
}

# === Vérification des dépendances ===
check_command tail
check_command awk
check_command /opt/wz_mini/inotifywait

# === Chargement des fichiers de configuration ===
MASTER_CONFIG="/opt/wz_mini/wz_mini.conf"
MQTT_CONFIG="/media/mmc/mosquitto/mosquitto.conf"

[[ -f "$MASTER_CONFIG" ]] || error_exit "Fichier manquant : $MASTER_CONFIG"
[[ -f "$MQTT_CONFIG" ]] || error_exit "Fichier manquant : $MQTT_CONFIG"

# shellcheck disable=SC1090
source "$MASTER_CONFIG"
# shellcheck disable=SC1090
source "$MQTT_CONFIG"

TOPIC_BASE="${MQTT_WYZE_TOPIC}/${CUSTOM_HOSTNAME}"

# === Fonction publication MQTT ===
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
        -m "$payload" || error_exit "Erreur publication MQTT sur $topic"
}

# === Surveillance du dossier /tmp/record/playlist/ ===
WATCH_DIR="/tmp/record/playlist"
LIST_FILE="${WATCH_DIR}/list.txt"

/opt/wz_mini/inotifywait -e moved_to -mr "$WATCH_DIR" | while read -r directory events filename; do
    if [[ "$filename" == "list.txt" ]]; then
        if [[ -f "$LIST_FILE" && -s "$LIST_FILE" ]]; then
            SEGMENT_NAME=$(tail -n 1 "$LIST_FILE")
            SEGMENT_NAME=$(echo "$SEGMENT_NAME" | tr -d '\r\n')

            if [[ -n "$SEGMENT_NAME" ]]; then
                SEGMENT_JSON="{\"name\":\"${SEGMENT_NAME}\"}"
                mqtt_publish "/segment" "$SEGMENT_JSON"
            else
                echo "⚠️  Fichier list.txt vide ou ligne vide" >&2
            fi
        else
            echo "⚠️  Fichier list.txt introuvable ou vide" >&2
        fi
    fi
done
