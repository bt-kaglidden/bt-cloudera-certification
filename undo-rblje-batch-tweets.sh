#! /usr/bin/env bash

# This script deletes single-shard collection in Solr

set -e

DATASET=rblje-batch-tweets

if [ -e /var/lib/cloudera-demovm/${DATASET}-create-collection.done ]; then
    solrctl collection --delete $DATASET
    sudo rm /var/lib/cloudera-demovm/${DATASET}-create-collection.done
fi

if [ -e /var/lib/cloudera-demovm/${DATASET}-create-dir.done ]; then
    solrctl instancedir --delete $DATASET
    sudo rm /var/lib/cloudera-demovm/${DATASET}-create-dir.done
fi

if [ -e /var/lib/cloudera-demovm/${DATASET}-generate.done ]; then
    rm -rf /home/cloudera/${DATASET}_configs
    sudo rm /var/lib/cloudera-demovm/${DATASET}-generate.done
fi
