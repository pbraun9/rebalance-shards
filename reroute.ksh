#!/bin/ksh
set -e

source /etc/rebalance-shards.conf

[[ -z $4 ]] && echo "usage: ${0##*/} index shard from_node to_node" && exit 1
idx=$1
shard=$2
from_node=$3
to_node=$4

[[ -z `echo $from_node | grep .mdb.yandexcloud.net` ]] && from_node=$from_node.mdb.yandexcloud.net
[[ -z `echo $to_node   | grep .mdb.yandexcloud.net` ]] &&   to_node=$to_node.mdb.yandexcloud.net

echo -n reroute index $idx shard $shard from ${from_node%\.mdb.yandexcloud.net} to ${to_node%\.mdb.yandexcloud.net} ...
#echo /tmp/dam.contrib.reroute.results.json

cat <<EOF > /tmp/dam.contrib.reroute.prep_request
{
  "commands": [
    {
      "move": {
        "index": "$idx",
        "shard": $shard,
        "from_node": "$from_node",
        "to_node": "$to_node"
      }
    }
  ]
}
EOF

cat /tmp/dam.contrib.reroute.prep_request | curl -fsSk -X POST -H "Content-Type: application/json" \
	"$endpoint/_cluster/reroute" -u $admin_user:$admin_passwd -d@- 2>&1 \
	> /tmp/dam.contrib.reroute.results.json && echo \ done

if (( $? > 0 )); then
	echo "POST /_cluster/reroute" && cat /tmp/dam.contrib.reroute.prep_request
#else
#	# jq -r ".state.blocks.indices.\"$idx\"" | \
#	count_relocating=`grep relocating_node /tmp/dam.contrib.reroute.results.json | grep -v null | wc -l`
#	echo \ count_relocating is $count_relocating
fi

