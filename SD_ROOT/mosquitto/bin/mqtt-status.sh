#!/opt/wz_mini/bin/bash

# same as /media/mmc/wz_mini/wz_mini.conf
MASTER_CONFIG="/opt/wz_mini/wz_mini.conf"
ICAMERA_CONFIG="/configs/.user_config"
MQTT_CONFIG="/media/mmc/mosquitto/mosquitto.conf"

source ${MASTER_CONFIG}
source ${MQTT_CONFIG}

TOPIC_BASE="${MQTT_WYZE_TOPIC}/${CUSTOM_HOSTNAME}"

mqtt_publish(){ # $1 = /my/topic  $2 = payload
	${MOSQUITTO_PUB_BIN} -h "${MQTT_BROKER_HOST}" -p "${MQTT_BROKER_PORT}" -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "${TOPIC_BASE}$1" ${MOSQUITTOPUBOPTS} ${MOSQUITTOOPTS} -m "$2"
}


/opt/wz_mini/inotifywait -e moved_to -mr /tmp/record/playlist/ |
while read -r directory events filename; do
  if [ "$filename" = "list.txt" ]; then
    SEGMENT_NAME=$(tail -1 /tmp/record/playlist/list.txt)
	SEGMENT_JSON="{\"name\":\"${SEGMENT_NAME}\"}"
	mqtt_publish "/segment" "${SEGMENT_JSON}"
  fi
done
