# rebalance opensearch shards

## description

in case you've got issues with zone awareness or some other reason for your cluster not to balance the shards properly, this set of scripts can help rebalance your shards manually.

## requirements

    apt install ksh jq curl

## install

    cd /data/
    git clone https://github.com/pbraun9/rebalance-shards.git

## setup

    vi /etc/rebalance-shards.conf

    endpoint=https://...:9200

    admin_user=...
    admin_passwd=...

## usage

    cd /data/rebalance-shards/

rebalance a single index for node storage optimization

    ./array-balance.ksh INDEX-NAME storage

other optimizations

    load1m
    load15m
    shards

### maintain roll-overs

enable a cron job to seek and rebalance newly created data-stream indices every 5 minute

    crontab -e

    # rebalance newly created data-stream indices
    */5 * * * * /data/rebalance-shards/wrapper-leafs.bash >> /var/log/rebalance-leafs.log 2>&1

### re-check once in a while

rebalance all shards with optimization depending on index size
-- beware this is only good for an already balanced cluster
-- otherwise it can create an enormous amount of relocations and cause disruption

    ./wrapper-all-indices.bash

