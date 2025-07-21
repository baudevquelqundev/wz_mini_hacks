#!/bin/sh
set -e

mkdaemon() {
    # dmon options:
    #   --stderr-redir  Redirect stderr to the log file as well
    #   --max-respawns  Number of times dmon will restart a failed process
    #   --environ       Set environment variable (disable buffering with LD_PRELOAD=libsetunbuf.so)
    #
    # dslog options (commented here, add if needed):
    #   --priority      Syslog priority
    #   --max-files     Number of rotated logs to keep

    local max_respawns=$1
    shift
    local daemon_name=$1
    shift

    dmon \
      --max-respawns "$max_respawns" \
      --environ "LD_PRELOAD=libsetunbuf.so" \
      "$@" \
      "$daemon_name"
}

# Lancer les daemons MQTT avec 0 redémarrage automatique
mkdaemon 0 mqtt-control /media/mmc/mosquitto/bin/mqtt-control.sh
mkdaemon 0 mqtt-status /media/mmc/mosquitto/bin/mqtt-status.sh
mkdaemon 0 mqtt-autodiscovery /media/mmc/mosquitto/bin/mqtt-autodiscovery.sh
