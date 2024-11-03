#!/bin/bash

max_reloc=2

function wait_reloc {
	reloc=`/data/rebalance-shards/show-shards.bash | grep RELOC`
	while (( `echo "$reloc" | wc -l` >= max_reloc )); do
		echo reached $max_reloc+ relocating shards, waiting 3 seconds
		sleep 3
		reloc=`/data/rebalance-shards/show-shards.bash | grep RELOC`
	done
	unset reloc
}

function process_b {
	echo
	echo ===== processing b =====
	echo
	for idx in `cat all-indices.b`; do
		wait_reloc
		../array-balance.ksh $idx shards
	done; unset idx
	echo
}

function process_kb {
	echo
	echo ===== processing kb =====
	echo
	for idx in `cat all-indices.kb`; do
		wait_reloc
		../array-balance.ksh $idx shards
	done; unset idx
	echo
}

function process_mb {
	echo
	echo ===== processing mb =====
	echo
	for idx in `cat all-indices.mb`; do
		wait_reloc
		../array-balance.ksh $idx shards
	done; unset idx
	echo
}

function process_gb {
	echo
	echo ===== processing gb =====
	echo
	for idx in `cat all-indices.gb`; do
		wait_reloc
		../array-balance.ksh $idx storage
	done; unset idx
	echo
}

mkdir -p traces/
cd traces/

# exclude generic indices which have more than 1 replica
# TODO for now those need to be balance manually - also check/rebalance those with this wrapper
all_indices=`../show-indices.bash | grep -vE ' .kibana| .opendistro| .opensearch| .ql-| .mdb| .plugins'`

echo
echo check for non-supported size types
tmp=`echo "$all_indices" | grep -vE 'gb$|mb$|kb$|[[:digit:]]+b$'`
[[ -n $tmp ]] && echo -e "found:\n$tmp" && exit 1
unset tmp
echo

echo writing all-indices.size_type
echo "$all_indices" | grep gb$ | awk '{print $3}' > all-indices.gb && echo \ all-indices.gb
echo "$all_indices" | grep mb$ | awk '{print $3}' > all-indices.mb && echo \ all-indices.mb
echo "$all_indices" | grep kb$ | awk '{print $3}' > all-indices.kb && echo \ all-indices.kb
echo "$all_indices" | grep -E '[[:digit:]]+b$' | awk '{print $3}' > all-indices.b && echo \ all-indices.b
echo

#process_b
#process_kb
#process_mb
process_gb

