#!/opt/wz_mini/bin/bash

# équivalent à /media/mmc/wz_mini/wz_mini.conf
MASTER_CONFIG="/opt/wz_mini/wz_mini.conf"  # pour récupérer CUSTOM_HOSTNAME'
MQTT_CONFIG="/media/mmc/mosquitto/mosquitto.conf"

source ${MASTER_CONFIG}
source ${MQTT_CONFIG}

mqtt_publish(){ # $1 = /my/topic  $2 = payload
    # Note: les messages sont RETAINED
	${MOSQUITTO_PUB_BIN} -h "${MQTT_BROKER_HOST}" -p "${MQTT_BROKER_PORT}" -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "$1" ${MOSQUITTOPUBOPTS} ${MOSQUITTOOPTS} -r -m "$2"
}

IP=$(ifconfig wlan0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')
MAC=$(ifconfig wlan0  | grep HWaddr | cut -d 'HW' -f2 | cut -d ' ' -f2)

# Données concernant l'appareil
#   {
#     "name": "Salon",
#     "mac": "98:CD:AC:D3:63:18",
#     "id": "WyzeV3",
#     "ip": "192.168.1.11"
#   }
DEVICE_JSON="{\"name\":\"${CUSTOM_HOSTNAME}\", \"mac\":\"${MAC}\", \"id\":\"WyzeV3\", \"ip\":\"${IP}\"}"
TOPIC_BASE="${MQTT_WYZE_TOPIC}/${CUSTOM_HOSTNAME}"

mqtt_publish "${TOPIC_BASE}/discovery" "${DEVICE_JSON}"