#!/bin/bash
set -e

source /etc/rebalance-shards.conf

curl -sk "$endpoint/_cat/indices?s=index" -u $admin_user:$admin_passwd

