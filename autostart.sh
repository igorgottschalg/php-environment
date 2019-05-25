#!/bin/bash
#sleep 999999
set -e
/bin/autostart/railgun.sh > /etc/railgun/railgun.conf 2>&1
/usr/bin/rg-listener -config=/etc/railgun/railgun.conf

exec /usr/bin/supervisord -n -c /etc/supervisord.conf