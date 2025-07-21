MASTER_CONFIG="/opt/wz_mini/wz_mini.conf"

source ${MASTER_CONFIG}

# On cree le serveur HTTP

# Le fichier de configuration pour le mot de passe
conffile="/tmp/httpd.conf"
if [[ -f $conffile ]]; then
    rm $conffile
fi

webpassword=$(busybox httpd -m "${RTSP_PASSWORD}")
authline="/:${RTSP_LOGIN}:$webpassword"

cat <<EOF > $conffile
$authline
EOF

# Le serveur HTTPD
httpd -p 8081 -h /tmp/record/ -r "auth" -c /tmp/httpd.conf


#!/bin/sh

# Commande FFMPEG à lancer
cmd="/opt/wz_mini/bin/ffmpeg -rtsp_transport udp -y -i rtsp://127.0.0.1:8554/1080p \
  -c:v copy -coder 1 -pix_fmt yuv420p -g 30 -bf 0 \
  -c:a libfdk_aac -afterburner 1 -channels 1 -b:a 128k -profile:a aac_he -ar 16000 \
  -strict experimental -aspect 16:9 \
  -f segment -segment_list /tmp/record/playlist/list.txt -segment_list_type flat \
  -segment_list_size 5 -segment_wrap 5 -segment_time 10 -reset_timestamps 1 \
  /tmp/record/stream_%d.mp4 -hide_banner -loglevel error"

# Fichier log d'erreurs
LOGFILE="/tmp/ffmpeg_loop.log"

# Nombre max de tentatives consécutives avant arrêt
MAX_ATTEMPTS=10
attempt=0

echo "=== Lancement FFMPEG boucle ===" > "$LOGFILE"

while true; do
    echo "[$(date)] Lancement de ffmpeg (tentative $((attempt+1)))" >> "$LOGFILE"
    
    $cmd >> "$LOGFILE" 2>&1
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo "[$(date)] ffmpeg s'est terminé normalement" >> "$LOGFILE"
        break
    else
        echo "[$(date)] ffmpeg a échoué avec code $exit_code" >> "$LOGFILE"
        attempt=$((attempt + 1))

        if [ $attempt -ge $MAX_ATTEMPTS ]; then
            echo "[$(date)] Trop d'échecs consécutifs. Arrêt de la boucle." >> "$LOGFILE"
            break
        fi

        echo "[$(date)] Nouvelle tentative dans 5s..." >> "$LOGFILE"
        sleep 5
    fi
done
