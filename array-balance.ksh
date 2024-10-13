#!/bin/ksh
set -e

(( debug = 0 ))
#(( debug = 1 ))

source /etc/rebalance-shards.conf

[[ -z $2 ]] && echo "usage: ${0##*/} <index> <load1m|load15m|shards|storage>" && exit 1
idx=$1
sort_type=$2

# allow to have pri vs rep duplicates
# e.g. if you want 9 pri shards over 9 nodes, you would also have 9 rep over the very same nodes
# which in fact makes duplicate shards in the cluster overall
(( flat_distribution = 0 ))

# only possible if number of shards /2 number of nodes - UNTESTED
#(( flat_distribution = 1 ))

# global variables
move_primary() {
	reloc=`echo "$shards_pri" | grep -E "[[:space:]]+$shard[[:space:]]+p[[:space:]]+RELOCATING"` || true
	if [[ -n $reloc ]]; then
		echo "\t primary shard $shard is already being relocated"
		echo "\t $reloc"
		unset reloc
		return
	fi

	[[ -z $rep_zone ]] && echo function $0 requires rep_zone && exit 1

	if [[ $rep_zone = rc1a ]]; then
		# cannot move primary shard $shard to node tmp2
		# as current replica lives there
		if [[ ${dest_nodes_pri1a[-1]} = $tmp2 ]]; then
			[[ -z ${dest_nodes_pri1a[-2]} ]] && \
				echo -e \\t no node left for primary in rc1b rc1d: && \
				echo "${dest_nodes_pri[@]}" | sed 's/^/\t /' && \
				echo -e \\t while this is what is left for replica: && \
				echo "${dest_nodes_rep[@]}" | sed 's/^/\t /' && \
				return
			new=${dest_nodes_pri1a[-2]}
		else
			[[ -z ${dest_nodes_pri1a[-1]} ]] && \
				echo -e \\t no node left for primary in rc1b rc1d: && \
				echo "${dest_nodes_pri[@]}" | sed 's/^/\t /' && \
				echo -e \\t while this is what is left for replica: && \
				echo "${dest_nodes_rep[@]}" | sed 's/^/\t /' && \
				return
			new=${dest_nodes_pri1a[-1]}
		fi
	elif [[ $rep_zone = rc1b ]]; then
		if [[ ${dest_nodes_pri1b[-1]} = $tmp2 ]]; then
			[[ -z ${dest_nodes_pri1b[-2]} ]] && \
				echo -e \\t no node left for primary in rc1b rc1d: && \
				echo "${dest_nodes_pri[@]}" | sed 's/^/\t /' && \
				echo -e \\t while this is what is left for replica: && \
				echo "${dest_nodes_rep[@]}" | sed 's/^/\t /' && \
				return
			new=${dest_nodes_pri1b[-2]}
		else
			[[ -z ${dest_nodes_pri1b[-1]} ]] && \
				echo -e \\t no node left for primary in rc1b rc1d: && \
				echo "${dest_nodes_pri[@]}" | sed 's/^/\t /' && \
				echo -e \\t while this is what is left for replica: && \
				echo "${dest_nodes_rep[@]}" | sed 's/^/\t /' && \
				return
			new=${dest_nodes_pri1b[-1]}
		fi
	elif [[ $rep_zone = rc1d ]]; then
		if [[ ${dest_nodes_pri1d[-1]} = $tmp2 ]]; then
			[[ -z ${dest_nodes_pri1d[-2]} ]] && \
				echo -e \\t no node left for primary in rc1b rc1d: && \
				echo "${dest_nodes_pri[@]}" | sed 's/^/\t /' && \
				echo -e \\t while this is what is left for replica: && \
				echo "${dest_nodes_rep[@]}" | sed 's/^/\t /' && \
				return
			new=${dest_nodes_pri1d[-2]}
		else
			[[ -z ${dest_nodes_pri1d[-1]} ]] && \
				echo -e \\t no node left for primary in rc1b rc1d: && \
				echo "${dest_nodes_pri[@]}" | sed 's/^/\t /' && \
				echo -e \\t while this is what is left for replica: && \
				echo "${dest_nodes_rep[@]}" | sed 's/^/\t /' && \
				return
			new=${dest_nodes_pri1d[-1]}
		fi
	fi

	[[ -z $new ]] && echo error: could not define primary to_node && exit 1

	dest_nodes_pri=( `echo ${dest_nodes_pri[@]} | sed "s/$new//"` )

	dest_nodes_pri1a=( `echo ${dest_nodes_pri1a[@]} | sed "s/$new//"` )
	dest_nodes_pri1b=( `echo ${dest_nodes_pri1b[@]} | sed "s/$new//"` )
	dest_nodes_pri1d=( `echo ${dest_nodes_pri1d[@]} | sed "s/$new//"` )

	echo -e "\t --> pri ${new%%\.mdb.yandexcloud.net}"
	if (( debug < 1 )); then
		/data/rebalance-shards/reroute.ksh $idx $shard $tmp $new | sed 's/^/\t /' || exit 1
		sleep 1
	fi
}

# global variables
move_replica() {
	reloc=`echo "$shards_rep" | grep -E "[[:space:]]+$shard[[:space:]]+r[[:space:]]+RELOCATING"` || true
	if [[ -n $reloc ]]; then
		echo "\t replica shard $shard is already being relocated"
		echo "\t $reloc"
	fi
	unset reloc

	# check current pri zone, take the first available rep (but in current pri zone), move rep
	# take the first available rep (but in current pri zone)

	pri_zone=`echo $tmp | sed -r 's/^(rc[[:digit:]][abd])-.*/\1/'`
	#echo DEBUG pri_zone $pri_zone

	#echo DEBUG dest_nodes_rep1a@ ${dest_nodes_rep1a[@]}
	#echo DEBUG dest_nodes_rep1b@ ${dest_nodes_rep1b[@]}
	#echo DEBUG dest_nodes_rep1d@ ${dest_nodes_rep1d[@]}

	# return 0 to keep running since we have -e

	if [[ $pri_zone = rc1a ]]; then
		[[ -z ${dest_nodes_rep1a[@]} ]] && \
			echo -e \\t no node left for replica in rc1b rc1d: && \
			echo "${dest_nodes_rep[@]}" | sed 's/^/\t /' && \
			echo -e \\t while this is what is left for primary: && \
			echo "${dest_nodes_pri[@]}" | sed 's/^/\t /' && \
		 	return

		rep=${dest_nodes_rep1a[-1]}

		dest_nodes_rep=( `echo ${dest_nodes_rep[@]} | sed "s/$rep//"` )

		unset 'dest_nodes_rep1a[-1]'
		dest_nodes_rep1b=( `echo ${dest_nodes_rep1b[@]} | sed "s/$rep//"` )
		dest_nodes_rep1d=( `echo ${dest_nodes_rep1d[@]} | sed "s/$rep//"` )
	elif [[ $pri_zone = rc1b ]]; then
		[[ -z ${dest_nodes_rep1b[@]} ]] && \
			echo -e \\t no node left for replica in rc1d rc1a: && \
			echo "${dest_nodes_rep[@]}" | sed 's/^/\t /' && \
			echo -e \\t while this is what is left for primary: && \
			echo "${dest_nodes_pri[@]}" | sed 's/^/\t /' && \
			return

		rep=${dest_nodes_rep1b[-1]}

		dest_nodes_rep=( `echo ${dest_nodes_rep[@]} | sed "s/$rep//"` )

		dest_nodes_rep1a=( `echo ${dest_nodes_rep1a[@]} | sed "s/$rep//"` )
		unset 'dest_nodes_rep1b[-1]'
		dest_nodes_rep1d=( `echo ${dest_nodes_rep1d[@]} | sed "s/$rep//"` )
	elif [[ $pri_zone = rc1d ]]; then
		[[ -z ${dest_nodes_rep1d[@]} ]] && \
			echo -e \\t no node left for replica in rc1a rc1b: && \
			echo "${dest_nodes_rep[@]}" | sed 's/^/\t /' && \
			echo -e \\t while this is what is left for primary: && \
			echo "${dest_nodes_pri[@]}" | sed 's/^/\t /' && \
			return

		rep=${dest_nodes_rep1d[-1]}

		dest_nodes_rep=( `echo ${dest_nodes_rep[@]} | sed "s/$rep//"` )

		dest_nodes_rep1a=( `echo ${dest_nodes_rep1a[@]} | sed "s/$rep//"` )
		dest_nodes_rep1b=( `echo ${dest_nodes_rep1b[@]} | sed "s/$rep//"` )
		unset 'dest_nodes_rep1d[-1]'
	else
		echo error: pri_zone $pri_zone is unknown zone && exit 1
	fi

	#echo DEBUG rep $rep

	[[ -z $rep ]] && echo error: could not define replica to_node && exit 1

	echo -e "\t --> rep ${rep%%\.mdb.yandexcloud.net}"
	if (( debug < 1 )); then
		/data/rebalance-shards/reroute.ksh $idx $shard $tmp2 $rep | sed 's/^/\t /' || exit 1
		sleep 1
	fi

	unset pri_zone
	# we keep rep to eventually define new (when there is DUP DUP)
}

#
# current shard shard distribution for a given index
#

shards=`curl -fsSk "$endpoint/_cat/shards" -u $admin_user:$admin_passwd | grep -E "^$idx[[:space:]]+"`

echo

# no RELOCATING no UNASSIGNED
#woo_shards=`echo "$shards" | grep -vE '[[:space:]]+[rp][[:space:]]+STARTED'` || true
#[[ -n $woo_shards ]] && echo -e "error: can only handle STARTED shards:\n$woo_shards" && exit 1

# no UNASSIGNED
woo_shards=`echo "$shards" | grep -E '[[:space:]]+[rp][[:space:]]+UNASSIGNED'` || true
[[ -n $woo_shards ]] && echo -e "error: can only handle UNASSIGNED shards just yet:\n$woo_shards" && exit 1

#pri_shards=`echo "$shards" | grep -E '[[:space:]]+p[[:space:]]+STARTED' | awk '{print $8}'`
#rep_shards=`echo "$shards" | grep -E '[[:space:]]+r[[:space:]]+STARTED' | awk '{print $8}'`

# if we handle both STARTED and RELOCATING then the shard count is fine,
# as long as we made sure there aren't any other kind of shards there
# TODO we avoided UNSASSIGNED but what about other possible kinds?
pri_shards=`echo "$shards" | grep -E '[[:space:]]+p[[:space:]]+(STARTED|RELOCATING)' | awk '{print $8}'`
rep_shards=`echo "$shards" | grep -E '[[:space:]]+r[[:space:]]+(STARTED|RELOCATING)' | awk '{print $8}'`

typeset -a cur_nodes=( $pri_shards )
typeset -a rep_nodes=( $rep_shards )

# keep those variables for further checking if shard is already relocating, before attempting to move it
#unset pri_shards rep_shards shards

#echo DEBUG ${cur_nodes[@]}

count_cur_nodes=${#cur_nodes[@]}
count_rep_nodes=${#rep_nodes[@]}

echo $idx has $count_cur_nodes primary and $count_rep_nodes replica shards

(( count_cur_nodes != count_rep_nodes )) && echo "error: current support only for number_of_replicas : 1" && exit 1

#
# target array of nodes for the shards to be moved to
#

# least 1 minute load at the array's end - nodes API
# cannot use api sorting: need to revert order (s=load_1m)
if [[ $sort_type = load1m ]]; then
	nodes_raw=`curl -fsSk "$endpoint/_cat/nodes" -u $admin_user:$admin_passwd`

	least=`echo "$nodes_raw" | grep data | sort -r -k5 -V | awk '{print $NF}'`
	if (( flat_distribution == 0 )); then
		typeset -a dest_nodes_pri=( $least )
		typeset -a dest_nodes_rep=( $least )
	else
		typeset -a dest_nodes=( $least )
	fi

	unset nodes_raw

elif [[ $sort_type = load15m ]]; then
	nodes_raw=`curl -fsSk "$endpoint/_cat/nodes" -u $admin_user:$admin_passwd`

	least=`echo "$nodes_raw" | grep data | sort -r -k7 -V | awk '{print $NF}'`
	if (( flat_distribution == 0 )); then
		typeset -a dest_nodes_pri=( $least )
		typeset -a dest_nodes_rep=( $least )
	else
		typeset -a dest_nodes=( $least )
	fi

	unset nodes_raw

# least number of shards at the array's end - allocation API
# cannot use api sorting: need to revert order (s=shards)
elif [[ $sort_type = shards ]]; then
        allocation_raw=`curl -fsSk "$endpoint/_cat/allocation" -u $admin_user:$admin_passwd`

	[[ -z $allocation_raw ]] && echo error: allocation_raw empty - cannot proceed && exit 1

	least=`echo "$allocation_raw" | sed -r 's/^[[:space:]]*//' | sort -r -V | awk '{print $NF}'`
	if (( flat_distribution == 0 )); then
		typeset -a dest_nodes_pri=( $least )
		typeset -a dest_nodes_rep=( $least )
	else
		typeset -a dest_nodes=( $least )
	fi

        unset allocation_raw

# least used storage at the array's end - allocation API
# aka most available space
# disk.avail col by the endpoint itself to handle gb mb kb w/o specifying bytes
elif [[ $sort_type = storage ]]; then
	allocation_raw=`curl -fsSk "$endpoint/_cat/allocation?s=disk.avail" -u $admin_user:$admin_passwd`

	least=`echo "$allocation_raw" | awk '{print $NF}'`
	if (( flat_distribution == 0 )); then
		typeset -a dest_nodes_pri=( $least )
		typeset -a dest_nodes_rep=( $least )
	else
		typeset -a dest_nodes=( $least )
	fi
        unset allocation_raw

fi

# we know we need to move the primary shard
# so we check replica zone and know where to place the new primary shard (any of the two other zones)
# this will be located on any mode BUT that zone
least_pri1a=`echo "$least" | grep -v ^rc1a-`
least_pri1b=`echo "$least" | grep -v ^rc1b-`
least_pri1d=`echo "$least" | grep -v ^rc1d-`

typeset -a dest_nodes_pri1a=( $least_pri1a )
typeset -a dest_nodes_pri1b=( $least_pri1b )
typeset -a dest_nodes_pri1d=( $least_pri1d )

unset least_pri1a least_pri1b least_pri1d

# this will be located on any mode BUT that zone
least_rep1a=`echo "$least" | grep -v ^rc1a-`
least_rep1b=`echo "$least" | grep -v ^rc1b-`
least_rep1d=`echo "$least" | grep -v ^rc1d-`

least_rep1ab=`echo "$least" | grep -vE '^rc1a-|rc1b-'`
least_rep1bd=`echo "$least" | grep -vE '^rc1b-|rc1d-'`
least_rep1da=`echo "$least" | grep -vE '^rc1d-|rc1a-'`

typeset -a dest_nodes_rep1a=( $least_rep1a )
typeset -a dest_nodes_rep1b=( $least_rep1b )
typeset -a dest_nodes_rep1d=( $least_rep1d )

typeset -a dest_nodes_rep1ab=( $least_rep1ab )
typeset -a dest_nodes_rep1bd=( $least_rep1bd )
typeset -a dest_nodes_rep1da=( $least_rep1da )

unset least_rep1a least_rep1b least_rep1d least_rep1ab least_rep1bd least_rep1da

#
# proceed with re-allocation
#

# current support only for pris == reps
# iterate over the pri arrays to find duplicate nodes
# iterate over the rep arrays to find duplicate nodes
# we need to iterate over the rep arrays in between so the rep zone check isn't worthless
# we need to know about possible new pri before iterating over rep
(( shard = 0 ))
until (( shard >= count_cur_nodes )); do
	[[ -z ${cur_nodes[$shard]} ]] && echo error: nothing on pri shard $shard && exit 1
	[[ -z ${rep_nodes[$shard]} ]] && echo error: nothing on rep shard $shard && exit 1

	tmp=${cur_nodes[$shard]}
	tmp2=${rep_nodes[$shard]}

	[[ -z $tmp ]] && echo error: tmp is empty - cannot proceed && exit 1
	[[ -z $tmp2 ]] && echo error: tmp2 is empty - cannot proceed && exit 1

	#echo DEBUG tmp $tmp
	#echo DEBUG tmp2 $tmp2

	#echo DEBUG ARRAY ${dest_nodes[@]}
	#echo DEBUG COUNT ${#dest_nodes[@]}
	#echo DEBUG LAST ITEM ${dest_nodes[-1]}

	echo \ shard $shard

	#echo DEBUG pri zone is $pri_zone
	#echo DEBUG rep zone is $rep_zone
	#echo DEBUG dest_nodes ${dest_nodes[@]}
	#echo DEBUG dest_nodes_pri ${dest_nodes[@]}
	#echo DEBUG dest_nodes_rep ${dest_nodes[@]}
	#echo DEBUG dest_nodes_pri1a@ ${dest_nodes_pri1a[@]}
	#echo DEBUG dest_nodes_pri1b@ ${dest_nodes_pri1b[@]}
	#echo DEBUG dest_nodes_pri1d@ ${dest_nodes_pri1d[@]}
	#echo DEBUG dest_nodes_rep1a@ ${dest_nodes_rep1a[@]}
	#echo DEBUG dest_nodes_rep1b@ ${dest_nodes_rep1b[@]}
	#echo DEBUG dest_nodes_rep1d@ ${dest_nodes_rep1d[@]}
	#echo DEBUG dest_nodes_rep1ab@ ${dest_nodes_rep1ab[@]}
	#echo DEBUG dest_nodes_rep1bd@ ${dest_nodes_rep1bd[@]}
	#echo DEBUG dest_nodes_rep1da@ ${dest_nodes_rep1da[@]}

	# also remove seen replica shard before the check for rep zone when moving pri
	# rep shard not seen before
	if [[ -n `echo ${dest_nodes_rep[@]} | grep $tmp2` ]]; then
		dest_nodes_rep=( `echo ${dest_nodes_rep[@]} | sed "s/$tmp2//"` )

		dest_nodes_rep1a=( `echo ${dest_nodes_rep1a[@]} | sed "s/$tmp2//"` )
		dest_nodes_rep1b=( `echo ${dest_nodes_rep1b[@]} | sed "s/$tmp2//"` )
		dest_nodes_rep1d=( `echo ${dest_nodes_rep1d[@]} | sed "s/$tmp2//"` )

		dest_nodes_rep1ab=( `echo ${dest_nodes_rep1ab[@]} | sed "s/$tmp2//"` )
		dest_nodes_rep1bd=( `echo ${dest_nodes_rep1bd[@]} | sed "s/$tmp2//"` )
		dest_nodes_rep1da=( `echo ${dest_nodes_rep1da[@]} | sed "s/$tmp2//"` )

		echo \ \ rep ${tmp2%%\.mdb.yandexcloud.net} OK
	else
		echo \ \ rep ${tmp2%%\.mdb.yandexcloud.net} DUP
		(( rep_is_dup = 1 ))
	fi

	# the current primary shard was not seen before - we remove it from the array
	if [[ -n `echo ${dest_nodes_pri[@]} | grep $tmp` ]]; then
		echo \ \ pri ${tmp%%\.mdb.yandexcloud.net} OK

		# we use the overall dest_nodes array for checking duplicates
		# althrough the real deal is into the zoned arrays

		dest_nodes_pri=( `echo ${dest_nodes_pri[@]} | sed "s/$tmp//"` )

		dest_nodes_pri1a=( `echo ${dest_nodes_pri1a[@]} | sed "s/$tmp//"` )
		dest_nodes_pri1b=( `echo ${dest_nodes_pri1b[@]} | sed "s/$tmp//"` )
		dest_nodes_pri1d=( `echo ${dest_nodes_pri1d[@]} | sed "s/$tmp//"` )

		# pri OK rep DUP (OK DUP)
		if (( rep_is_dup == 1 )); then
			move_replica
		fi

	# the current primary shard was already seen - we attempt to move it
	else
		echo \ \ pri ${tmp%\.mdb.yandexcloud.net} DUP

		# pri DUP rep DUP (DUP DUP)
		if (( rep_is_dup == 1 )); then
			# define rep zone from target rep, define and move new accordingly

			move_replica

			# we keep running even if move_replica returned
			if [[ -z $rep ]]; then
				rep_zone=`echo $tmp2 | sed -r 's/^(rc[[:digit:]][abd])-.*/\1/'`

				move_primary
			else
				rep_zone=`echo $rep | sed -r 's/^(rc[[:digit:]][abd])-.*/\1/'`

				move_primary
			fi

		# pri DUP rep OK (DUP OK)
		else
			# define current rep zone, move new pri accordingly

			rep_zone=`echo $tmp2 | sed -r 's/^(rc[[:digit:]][abd])-.*/\1/'`

			move_primary
		fi
		unset new new_zone

	# end primary shard seen / not seen
	fi
	unset rep_is_dup rep rep_zone

	(( shard++ ))

	unset tmp tmp2
done
echo

if (( debug > 0 )); then
	#echo DEBUG dest_nodes ${dest_nodes[@]}
	#echo DEBUG dest_nodes_pri ${dest_nodes[@]}
	#echo DEBUG dest_nodes_rep ${dest_nodes[@]}
	echo DEBUG dest_nodes_pri1a@ ${dest_nodes_pri1a[@]}
	echo DEBUG dest_nodes_pri1b@ ${dest_nodes_pri1b[@]}
	echo DEBUG dest_nodes_pri1d@ ${dest_nodes_pri1d[@]}
	echo DEBUG dest_nodes_rep1a@ ${dest_nodes_rep1a[@]}
	echo DEBUG dest_nodes_rep1b@ ${dest_nodes_rep1b[@]}
	echo DEBUG dest_nodes_rep1d@ ${dest_nodes_rep1d[@]}
	#echo DEBUG dest_nodes_rep1ab@ ${dest_nodes_rep1ab[@]}
	#echo DEBUG dest_nodes_rep1bd@ ${dest_nodes_rep1bd[@]}
	#echo DEBUG dest_nodes_rep1da@ ${dest_nodes_rep1da[@]}
	echo

shards=`curl -fsSk "$endpoint/_cat/shards" -u $admin_user:$admin_passwd | grep -E "^$idx[[:space:]]+"`

echo "$shards"
echo
fi

