#!/bin/bash

/usr/sbin/vcmd -c /tmp/pycore.1/n24 -- bash -E -c 'for i in `seq 1 300`; do while true; do wget -r -q -k http://www-uba >/dev/null; done & done;' &

/usr/sbin/vcmd -c /tmp/pycore.1/n31 -- bash -E -c 'for i in `seq 1 300`; do while true; do wget -r -q -k http://www-uba >/dev/null; done & done;' &

/usr/sbin/vcmd -c /tmp/pycore.1/n43 -- bash -E -c 'for i in `seq 1 300`; do while true; do wget -r -q -k http://www-uba >/dev/null; done & done;' &

