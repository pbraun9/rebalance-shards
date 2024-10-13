#!/bin/ksh
set -e

source /etc/rebalance-shards.conf

[[ -z $1 ]] && echo index? && exit 1
idx=$1

echo one replicas on $idx

cat <<EOF | curl -fsSk -X PUT -m 3 -H "Content-Type: application/json" \
        "$endpoint/$idx/_settings" -u $admin_user:$admin_passwd -d@- 2>&1 \
        > /tmp/dam.contrib.one-replica.results.json && echo done
{
  "number_of_replicas": 1
}
EOF

(( $? > 0 )) && cat <<EOF || true
PUT /$idx/_settings
{
  "number_of_replicas": 1
}
EOF

