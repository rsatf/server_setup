#!/usr/bin/env bash

/home/steam/tf2/server/srcds_run -console -usercon -game tf +ip 0.0.0.0 \
-timeout 5 -strictportbind -nobots +map cp_granary \
+clientport 27005 +servercfgfile server.cfg \
+sv_pure 1 +randommap +maxplayers 24 \
+sv_setsteamaccount 320975511A0F7213417257E38871B836