# rebalance opensearch shards

## description

in case you've got issues with zone awareness, or some other reason for your cluster not to balance the shards properly, this set of scripts can help rebalance your shards manually.

## requirements

KSH93 has better arithmetics

    apt install ksh jq curl

disable shards re-balance in Dev Tools

```
PUT /_cluster/settings
{
  "transient" : {
    "cluster.routing.rebalance.enable": "none"
  }
}
PUT /_cluster/settings
{
  "persistent" : {
    "cluster.routing.rebalance.enable": "none"
  }
}
```

eventually allow more storage flexibility during bulk shard relocations

```
PUT _cluster/settings
{
  "transient": {
    "cluster.routing.allocation.disk.watermark.low": "90%",
    "cluster.routing.allocation.disk.watermark.high": "93%",
    "cluster.routing.allocation.disk.watermark.flood_stage": "96%",
    "cluster.info.update.interval": "10m"
  }
}
```

and check

    GET _cluster/settings?flat_settings=true

## install

    mkdir -p /data/
    cd /data/
    git clone https://github.com/pbraun9/rebalance-shards.git

## setup

    vi /etc/rebalance-shards.conf

    endpoint=https://...:9200

    admin_user=...
    admin_passwd=...

## usage

    cd /data/rebalance-shards/

show unbalanced primary and replica shards

    ./show-unbalanced-shards.ksh

rebalance a single index for node storage optimization

    ./array-balance.ksh INDEX-NAME storage

other optimizations

    load1m
    load15m
    shards

show relocating (and unassigned) shards in a loop

    watch "./show-shards.bash | grep -v STARTED"

### check all leafs

generate list of writing indices from datastreams

    cd traces/
    ../show-data-streams-leaf.bash > leafs

and check all those are well balanced

    for idx in `cat leafs`; do ../array-balance.ksh $idx load15m; sleep 1; done; unset idx

### maintain roll-overs

enable a cron job to seek and rebalance newly created data-stream indices

    crontab -e

    # rebalance newly created datastream indices
    */15 * * * * /data/rebalance-shards/wrapper-new-leafs.bash >> /var/log/rebalance-leafs.log

### re-check all indices

this is not absolutely necessary for datastreams, as only the writing index eats hardware resources,
but it can be useful once in a while esp. for increasing search (read) performance

rebalance all shards with optimization depending on index size
-- beware this is only good for an already balanced cluster
-- otherwise it can create an enormous amount of relocations and cause disruption

    time ./wrapper-all-indices2.bash

and to rebalance only writing indices from datastreams

    time ./wrapper-leaf-indices.bash

