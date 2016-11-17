#!/bin/bash

set -x
sleep 10
/usr/bin/find /opt/prometheus/data/ -type f -name LOCK -delete
rm -f /opt/prometheus/data/DIRTY
/usr/local/bin/prometheus -config.file=/etc/prometheus/prometheus.yml -web.external-url=https://$PUBLIC_IP/prom/ -storage.local.path=/opt/prometheus/data &
sleep 5

curl consul.service.consul:8500/v1/kv/prometheus-entrypoint.sh | jq .[].Value -r | base64 -d | sh

: << KOMMENT
/usr/local/bin/consul-template \
       -consul consul.service.consul:8500 \
       -template <(echo '{{key "etc/prometheus/config.yml"}}'):/etc/prometheus/prometheus.yml:"kill -HUP $(pidof prometheus)" \
       -template <(echo '{{key "etc/prometheus/rules/all-rules.rule"}}'):/etc/prometheus/rules/all-rules.rule:"kill -HUP $(pidof prometheus)" \
       -template <(echo '{{key "etc/prometheus/sdiscovery/node_collector.yml"}}' ):/etc/prometheus/sdiscovery/node_collector.yml:"kill -HUP $(pidof prometheus)" \
       -template <(echo '{{key "etc/prometheus/sdiscovery/jmx_exporter.yml"}}' ):/etc/prometheus/sdiscovery/jmx_exporter.yml:"kill -HUP $(pidof prometheus)"
KOMMENT
