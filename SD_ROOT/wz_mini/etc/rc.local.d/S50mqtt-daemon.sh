#!/bin/sh

mkdaemon() {
    # dmon options
    #   --stderr-redir  Redirects stderr to the log file as well
    #   --max-respawns  Sets the number of times dmon will restart a failed process
    #   --environ       Sets an environment variable. Used to remove buffering on stdout
    #
    # dslog options
    #   --priority      The syslog priority. Set to DEBUG as these are just the stdout of the 
    #   --max-files     The number of logs that will exist at once
    #
    max_respawns=$1
    shift
    daemon_name=$1
    shift
    dmon \
      --max-respawns $max_respawns \
      --environ "LD_PRELOAD=libsetunbuf.so" \
      $@ \
        $daemon_name
}

mkdaemon 0 mqtt-control /media/mmc/mosquitto/bin/mqtt-control.sh
mkdaemon 0 mqtt-status /media/mmc/mosquitto/bin/mqtt-status.sh
mkdaemon 0 mqtt-autodiscovery /media/mmc/mosquitto/bin/mqtt-autodiscovery.sh


