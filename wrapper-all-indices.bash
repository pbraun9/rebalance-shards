#!/bin/bash

mkdir -p traces/
cd traces/

# exclude generic indices which have more than 1 replica
# TODO for now those need to be balance manually - also check/rebalance those with this wrapper
all_indices=`../show-indices.bash | grep -vE ' .kibana| .opendistro| .opensearch| .ql-| .mdb| .plugins'`

echo
echo found non-supported size types?
echo "$all_indices" | grep -vE 'gb$|mb$|kb$|[[:digit:]]+b$' || true
echo

echo writing all-indices.size_type
echo "$all_indices" | grep gb$ | awk '{print $3}' > all-indices.gb && echo \ all-indices.gb
echo "$all_indices" | grep mb$ | awk '{print $3}' > all-indices.mb && echo \ all-indices.mb
echo "$all_indices" | grep kb$ | awk '{print $3}' > all-indices.kb && echo \ all-indices.kb
echo "$all_indices" | grep -E '[[:digit:]]+b$' | awk '{print $3}' > all-indices.b && echo \ all-indices.b
echo

function process_b {
	echo processing b
	for idx in `cat all-indices.b`; do
		../array-balance.ksh $idx shards
	done; unset idx
	echo
}

function process_kb {
	echo processing kb
	for idx in `cat all-indices.kb`; do
		../array-balance.ksh $idx shards
	done; unset idx
	echo
}

function process_mb {
	echo processing mb
	for idx in `cat all-indices.mb`; do
		../array-balance.ksh $idx shards
	done; unset idx
	echo
}

function process_gb {
	echo processing gb
	for idx in `cat all-indices.gb`; do
		../array-balance.ksh $idx storage
	done; unset idx
	echo
}

process_b
process_kb
process_mb
process_gb

