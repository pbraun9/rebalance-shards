#!/bin/bash

#debug=1

[[ ! -d /data/rebalance-shards/ ]] && echo install rebalance-shards first && exit 1

mkdir -p /data/rebalance-shards/traces/
cd /data/rebalance-shards/traces/

(( debug > 0 )) && echo -n backup as leafs.old ...
[[ ! -f leafs ]] && touch leafs
mv -f leafs leafs.old && (( debug > 0 )) && echo done

(( debug > 0 )) && echo -n writing leafs ...
../show-data-streams-leaf.bash > leafs && (( debug > 0 )) && echo done

oldmd5=`md5sum leafs.old | awk '{print $1}'`
newmd5=`md5sum leafs | awk '{print $1}'`

if [[ ! $oldmd5 = $newmd5 ]]; then
	date -R
	echo \ new indices are:

	idxen=`diff leafs.old leafs | sed -rn 's/^> (.*)/\1/p'`

	# todo eventually record all removed indices whatever new ones appeared or not
	if [[ -z $idxen ]]; then
		echo \ info: no _new_ index - but some got removed
		diff leafs.old leafs
		echo
		exit 1
	fi

	echo "$idxen"

	for idx in $idxen; do
		../array-balance.ksh $idx load15m
	done; unset idx
else
	if (( debug > 0 )); then
		date -R
		echo no changes
	fi
fi

# BUGS
# - if you delete a stream and re-create it within the cron-job period, it won't get catched by the diff

