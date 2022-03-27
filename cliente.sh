#/usr/sbin/vcmd -c /tmp/pycore.1/n5 -- bash -E -c "hping3 -S 207.248.74.10 -p 80" &>/dev/null &


/usr/sbin/vcmd -c /tmp/pycore.1/n34 -- bash -E -c "while true; do echo -n 'n34: '; curl -s -q -w \"%{time_connect} + %{time_starttransfer} = %{time_total}\n\" http://www-uba -o /dev/null; sleep \$((1 + \$RANDOM % 10)); done" &

sleep 3

/usr/sbin/vcmd -c /tmp/pycore.1/n5 -- bash -E -c "while true; do echo -n 'n5: '; curl -s -q -w \"%{time_connect} + %{time_starttransfer} = %{time_total}\n\" http://www-uba -o /dev/null; sleep \$((1 + \$RANDOM % 10)); done" &

# ps axu | grep "bash -E -c while true;"| awk '{print $2}' | xargs sudo kill -9