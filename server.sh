#!/usr/bin/env bash

/home/steam/servers/pug1/srcds_run -console -usercon -game tf +ip 129.232.150.15 \
-timeout 5 -strictportbind -nobots +map mge_training_v8_beta4b \
+servercfgfile server.cfg \
-port 27015 \
+tv_port 27020 \
+clientport 40001 \
-steamport 30001 \
+sv_pure 1 +maxplayers 24 \
-debug \
-autoupdate \
-steam_dir /home/steam/tf2 \
-steamcmd_script /home/steam/tf2/server/update_tf.txt
