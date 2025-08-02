#!/bin/bash

printenv | awk -F= '{print "export " "\""$1"\"""=""\""$2"\"" }'  > /app/env.sh

echo "$CRON root  /bin/bash /app/app.sh >> /var/log/cron.log 2>&1"  > /etc/cron.d/hello-cron

cron 
tail -f /var/log/cron.log
