#!/bin/bash

[[ ! -d /data/rebalance-shards/ ]] && echo install rebalance-shards first && exit 1

mkdir -p /data/rebalance-shards/traces/

cd /data/rebalance-shards/traces/

#echo -n backup as leafs.old ...
mv -f leafs leafs.old

#echo -n writing leafs ...
../show-data-streams-leaf.bash > leafs

oldmd5=`md5sum leafs.old | awk '{print $1}'`
newmd5=`md5sum leafs | awk '{print $1}'`

if [[ ! $oldmd5 = $newmd5 ]]; then
	idxen=`diff leafs.old leafs | sed -rn 's/^> (.*)/\1/p'`
	date --rfc-email
	echo changed indices are:
	echo "$idxen"

	for idx in $idxen; do
		../array-balance.ksh $idx load15m
	done; unset idx
fi

