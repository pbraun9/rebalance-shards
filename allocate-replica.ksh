#!/bin/ksh
set -e

source /etc/dam/dam.conf

[[ -z $3 ]] && echo "usage: ${0##*/} index unassigned-shard node" && exit 1
idx=$1
shard=$2
node=$3

echo -n allocate index $idx shard $shard to node ${node%\.mdb.yandexcloud.net} ...
#echo /tmp/dam.contrib.allocate.results.json

cat <<EOF > /tmp/dam.contrib.allocate.prep_request
{
  "commands": [
    {
      "allocate_replica": {
        "index": "$idx",
        "shard": $shard,
        "node": "$node"
      }
    }
  ]
}
EOF

cat /tmp/dam.contrib.allocate.prep_request | curl -fsSk -X POST -H "Content-Type: application/json" \
	"$endpoint/_cluster/reroute" -u $admin_user:$admin_passwd -d@- 2>&1 \
	> /tmp/dam.contrib.allocate.results.json && echo \ done

if (( $? > 0 )); then
	echo "POST /_cluster/reroute" && cat /tmp/dam.contrib.allocate.prep_request
fi

