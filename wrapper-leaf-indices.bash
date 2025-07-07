#!/bin/bash

# GET _cat/nodes?v&s=name | grep data
(( nodes_num = 9 ))

(( max_reloc = nodes_num / 3 ))

echo debug max_reloc is $max_reloc

function wait_reloc {
	reloc=`/data/rebalance-shards/show-shards.bash | grep RELOC`
	while (( `echo "$reloc" | wc -l` >= max_reloc )); do
		echo \ reached $max_reloc+ relocating shards, waiting 3 seconds
		sleep 3
		reloc=`/data/rebalance-shards/show-shards.bash | grep RELOC`
	done
	unset reloc
}

mkdir -p traces/
cd traces/

leaf_indices=`../show-data-streams-leaf.bash`

for idx in $leaf_indices; do
	wait_reloc
	../array-balance.ksh $idx load15m
done; unset idx
echo

