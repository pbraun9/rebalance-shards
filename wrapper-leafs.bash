#!/bin/bash

[[ ! -d /data/rebalance-shards/ ]] && echo install rebalance-shards first && exit 1

mkdir -p /data/rebalance-shards/traces/

cd /data/rebalance-shards/traces/

#echo -n backup as leafs.old ...
[[ ! -f leafs ]] && touch leafs
mv -f leafs leafs.old

#echo -n writing leafs ...
../show-data-streams-leaf.bash > leafs

oldmd5=`md5sum leafs.old | awk '{print $1}'`
newmd5=`md5sum leafs | awk '{print $1}'`

if [[ ! $oldmd5 = $newmd5 ]]; then
	date --rfc-email
	echo changed indices are:

	idxen=`diff leafs.old leafs | sed -rn 's/^> (.*)/\1/p'`

	if [[ -z $idxen ]]; then
		echo no new index - those are the changes:
		diff leafs.old leafs
		exit 0
	fi

	echo "$idxen"

	for idx in $idxen; do
		../array-balance.ksh $idx load15m
	done; unset idx
fi

# BUGS
# - if you delete a stream and re-create it within the cron-job period, it won't get catched by the diff

