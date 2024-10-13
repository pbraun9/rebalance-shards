#!/bin/ksh
set -e

# handle both pri and rep shards
# assuming either replicas=0 or replicas=1

function eval_re_allocate {
	shard_names_pri=`echo "$shards_raw" | grep -E "^$idx[[:space:]]+" | grep -E '[[:space:]]+p[[:space:]]+STARTED' | awk '{print $8}'`
	shard_names_rep=`echo "$shards_raw" | grep -E "^$idx[[:space:]]+" | grep -E '[[:space:]]+r[[:space:]]+STARTED' | awk '{print $8}'`
	typeset -a pri_nodes=( $shard_names_pri )
	typeset -a rep_nodes=( $shard_names_rep )
	unset shard_names_pri shard_names_rep

	#echo DEBUG pri_nodes@ ${pri_nodes[@]}
	#echo DEBUG rep_nodes@ ${rep_nodes[@]}

	(( debug > 0 )) && echo $idx has ${#pri_nodes[@]} primary and ${#rep_nodes[@]} replica shards

	# target array of nodes for the shards to be moved to
        typeset -a dest_nodes_pri=( $nodes_list_bkp )
        typeset -a dest_nodes_rep=( $nodes_list_bkp )

	# virtually proceed with re-allocation
	(( shard = 0 ))
	until (( shard >= ${#pri_nodes[@]} )); do
		[[ -z ${pri_nodes[$shard]} ]] && echo error: nothing on idx $idx pri shard $shard && exit 1

		tmp=${pri_nodes[$shard]}

		[[ -n `echo ${dest_nodes_pri[@]} | grep $tmp` ]] && \
			dest_nodes_pri=( `echo ${dest_nodes_pri[@]} | sed "s/$tmp//"` ) || \
			echo $idx primary shard $shard is duplicate on $tmp

		(( shard++ ))

		unset tmp
	done

	(( shard = 0 ))
	until (( shard >= ${#rep_nodes[@]} )); do
		[[ -z ${rep_nodes[$shard]} ]] && echo error: nothing on idx $idx rep shard $shard && exit 1

		tmp2=${rep_nodes[$shard]}

		[[ -n `echo ${dest_nodes_rep[@]} | grep $tmp2` ]] && \
			dest_nodes_rep=( `echo ${dest_nodes_rep[@]} | sed "s/$tmp2//"` ) || \
			echo $idx replica shard $shard is duplicate on $tmp2

		(( shard++ ))

		unset tmp2
	done
}

source /etc/rebalance-shards.conf

nodes_list_bkp=`curl -fsSk "$endpoint/_cat/nodes" -u $admin_user:$admin_passwd | grep data | awk '{print $NF}'`

shards_raw=`curl -fsSk "$endpoint/_cat/shards" -u $admin_user:$admin_passwd | sort -V`

# this is just a dry-run hence we crawl through absolutely all indices
index_names=`echo "$shards_raw" | awk '{print $1}' | uniq`

for idx in $index_names; do
	eval_re_allocate
done; unset idx

