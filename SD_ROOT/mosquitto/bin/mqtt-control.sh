#!/opt/wz_mini/bin/bash

# S'abonne aux messages MQTT pour déclencher des actions

# Messages supportés:
# 	/leds/red/set ON|OFF
# 	/leds/blue/set ON|OFF
# 	/play <filename.wav> <volume_1-100>

MASTER_CONFIG="/opt/wz_mini/wz_mini.conf"
ICAMERA_CONFIG="/configs/.user_config"
MQTT_CONFIG="/media/mmc/mosquitto/mosquitto.conf"

source ${MASTER_CONFIG}
source ${MQTT_CONFIG}

TOPIC_BASE="${MQTT_WYZE_TOPIC}/${CUSTOM_HOSTNAME}"

mqtt_publish(){ # $1 = /my/topic  $2 = payload
	${MOSQUITTO_PUB_BIN} -h "${MQTT_BROKER_HOST}" -p "${MQTT_BROKER_PORT}" -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "${TOPIC_BASE}$1" ${MOSQUITTOPUBOPTS} ${MOSQUITTOOPTS} -m "$2"
}



# On s'abonne continuellement
# On émet un /disconnected comme last-will (en cas de déconnexion de la caméra au broker)
${MOSQUITTO_SUB_BIN} -v -h "${MQTT_BROKER_HOST}" -p "${MQTT_BROKER_PORT}" -u "${MQTT_USERNAME}" -P "${MQTT_PASSWORD}" -t "${TOPIC_BASE}/#"  ${MOSQUITTOOPTS} --will-topic "${TOPIC_BASE}/disconnected" | while read -r line ; do
  case $line in

	"${TOPIC_BASE}/status "*)
      mqtt_publish "/connected" ""
    ;;

	"${TOPIC_BASE}/leds/red/set ON")
      echo '0' > /sys/devices/virtual/gpio/gpio38/value
	;;

	"${TOPIC_BASE}/leds/red/set OFF")
      echo '1' > /sys/devices/virtual/gpio/gpio38/value
	;;

	"${TOPIC_BASE}/leds/blue/set ON")
      echo '0' > /sys/devices/virtual/gpio/gpio39/value
	;;

	"${TOPIC_BASE}/leds/blue/set OFF")
      echo '1' > /sys/devices/virtual/gpio/gpio39/value
	;;

	# ..../play <filename.wav> <volume_1-100>
	"${TOPIC_BASE}/play "*)
	  AUDIOFILE=$(echo "$line" | awk '{print $2}')
	  VOLUME=$(echo "$line" | awk '{print $3}')
	  VOLUME=${VOLUME:50}
	  cmd aplay "${AUDIOFILE}" "${VOLUME}"
	;;

  esac
done
