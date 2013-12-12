#! /usr/bin/env bash

# This script deletes the collection created in batch-tweets.sh,
# the original Cloudera sample.


set -e

if [ -e /var/lib/cloudera-demovm/batch-tweets-create-collection.done ]; then
    solrctl collection --delete batch_tweets
    sudo rm /var/lib/cloudera-demovm/batch-tweets-create-collection.done
fi

if [ -e /var/lib/cloudera-demovm/batch-tweets-create-dir.done ]; then
    solrctl instancedir --delete batch_tweets
    sudo rm /var/lib/cloudera-demovm/batch-tweets-create-dir.done
fi

if [ -e /var/lib/cloudera-demovm/batch-tweets-generate.done ]; then
    rm -rf /home/cloudera/batch_tweets_configs
    sudo rm /var/lib/cloudera-demovm/batch-tweets-generate.done
fi
