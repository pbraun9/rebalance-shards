#!/bin/bash
set -e

source /etc/rebalance-shards.conf

data_streams=`curl -fsSk "$endpoint/_data_stream/?pretty" -u $admin_user:$admin_passwd | jq -r '.data_streams[].name'`

for data_stream in $data_streams; do
	curl -fsSk "$endpoint/_data_stream/$data_stream?pretty" -u $admin_user:$admin_passwd | \
		jq -r '.data_streams[].indices[].index_name' | sort -V | tail -1
done; unset data_stream

