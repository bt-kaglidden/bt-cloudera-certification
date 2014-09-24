#! /usr/bin/env bash

# This script deletes single-shard collection in Solr

set -ue

DATASET=$1

if [ -e /var/lib/$USER-demovm/${DATASET}-create-collection.done ]; then
    solrctl collection --delete $DATASET
    sudo rm /var/lib/$USER-demovm/${DATASET}-create-collection.done
fi

if [ -e /var/lib/$USER-demovm/${DATASET}-create-dir.done ]; then
    solrctl instancedir --delete $DATASET
    sudo rm /var/lib/$USER-demovm/${DATASET}-create-dir.done
fi

if [ -e /var/lib/$USER-demovm/${DATASET}-generate.done ]; then
    rm -rf /home/$USER/${DATASET}_configs
    sudo rm /var/lib/$USER-demovm/${DATASET}-generate.done
fi
