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


# La commande FFMPEG, en cas d echec on reboot
cmd="/opt/wz_mini/bin/ffmpeg -rtsp_transport udp -y -i rtsp://${RTSP_LOGIN}:${RTSP_PASSWORD}@0.0.0.0:8554/unicast -c:v copy -coder 1 -pix_fmt yuv420p -g 30 -bf 0 -c:a libfdk_aac -afterburner 1 -channels 1 -b:a 128k -profile:a aac_he -ar 16000 -strict experimental -aspect 16:9 -f segment -segment_list /tmp/record/playlist/list.txt -segment_list_type flat -segment_list_size 5 -segment_wrap 5 -segment_time 10 -reset_timestamps 1 /tmp/record/stream_%d.mp4 -hide_banner -loglevel error"

until $cmd ; do
        reboot
done