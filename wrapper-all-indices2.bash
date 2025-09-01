#!/bin/bash

#tune=load15m
tune=shards

# GET _cat/nodes?v&s=name | grep data
(( nodes_num = 9 ))

(( max_reloc = nodes_num / 3 ))

echo debug max_reloc is $max_reloc

function wait_reloc {
	reloc=`/data/rebalance-shards/show-shards.bash | grep -v STARTED`
	while (( `echo "$reloc" | wc -l` >= max_reloc )); do
		echo \ reached $max_reloc+ failed-or-relocating shards, waiting 3 seconds
		sleep 3
		reloc=`/data/rebalance-shards/show-shards.bash | grep -v STARTED`
	done
	unset reloc
}

mkdir -p traces/
cd traces/

# _cat has a max amount of indices to show by default
# workaround that with another api
# todo - also catch non-datastream indices
source /etc/dam/dam.conf
all_indices=`curl -fsSk "$endpoint/_data_stream/?pretty" -u $admin_user:$admin_passwd | jq -r '.data_streams[].indices[].index_name'`
#| grep -vE '^.kibana|^.opendistro|^.opensearch|^.ql-|^.mdb|^.plugins'

for idx in $all_indices; do
	wait_reloc
	echo checking $idx
	../array-balance.ksh $idx $tune
done; unset idx
echo

date -R
echo

