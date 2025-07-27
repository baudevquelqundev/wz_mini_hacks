#!/bin/bash
set -euo pipefail

MASTER_CONFIG="/opt/wz_mini/wz_mini.conf"

# Charger la config principale
source "${MASTER_CONFIG}"

# Création du fichier de configuration HTTP avec authentification
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

# ---------------------------------
# Boucle pour lancer ffmpeg en continu
# ---------------------------------

cmd="/opt/wz_mini/bin/ffmpeg -rtsp_transport tcp -y -i rtsp://127.0.0.1:8554/1080p \
    -map 0:v:0 -map 0:a:0 \
    -c:v copy \
    -c:a copy \
    -f segment \
    -segment_list /tmp/record/playlist/list.txt -segment_list_type flat \
    -segment_list_size 5 -segment_wrap 5 -segment_time 10 -reset_timestamps 1 \
    /tmp/record/stream_%d.mp4 -hide_banner -loglevel error"

LOGFILE="/tmp/ffmpeg_loop.log"
MAX_ATTEMPTS=10
attempt=0

echo "=== Lancement FFMPEG boucle ===" > "$LOGFILE"

while true; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Lancement de ffmpeg (tentative $((attempt + 1)))" >> "$LOGFILE"
    
    if $cmd >> "$LOGFILE" 2>&1; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ffmpeg s'est terminé normalement." >> "$LOGFILE"
        break
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ffmpeg a échoué avec code $?" >> "$LOGFILE"
        attempt=$((attempt + 1))
        
        if [ "$attempt" -ge "$MAX_ATTEMPTS" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Trop d'échecs consécutifs. Arrêt de la boucle." >> "$LOGFILE"
            break
        fi
        
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Nouvelle tentative dans 5 secondes..." >> "$LOGFILE"
        sleep 5
    fi
done
