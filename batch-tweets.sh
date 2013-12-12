#! /usr/bin/env bash

# (Original Cloudera sample)
# This script creates a single-shard collection in Solr
# and loads a set of artificial/generated tweets into
# the collection using the MapReduce indexer and GoLive

set -e

sudo mkdir -p /var/lib/cloudera-demovm

if [ ! -e /var/lib/cloudera-demovm/batch-tweets-generate.done ]; then
    solrctl instancedir --generate /home/cloudera/batch_tweets_configs
    cp -f /usr/share/doc/search*/examples/solr-nrt/collection1/conf/schema.xml /home/cloudera/batch_tweets_configs/conf/
    sudo touch /var/lib/cloudera-demovm/batch-tweets-generate.done
fi

if [ ! -e /var/lib/cloudera-demovm/batch-tweets-create-dir.done ]; then
    solrctl instancedir --create batch_tweets /home/cloudera/batch_tweets_configs
    sudo touch /var/lib/cloudera-demovm/batch-tweets-create-dir.done
fi

if [ ! -e /var/lib/cloudera-demovm/batch-tweets-create-collection.done ]; then
    solrctl collection --create batch_tweets -s 1
    sudo touch /var/lib/cloudera-demovm/batch-tweets-create-collection.done
fi

set +e
hadoop fs -rm -r -skipTrash /user/cloudera/batch_tweets_indir
hadoop fs -rm -r -skipTrash /user/cloudera/batch_tweets_outdir
set -e

hadoop fs -mkdir -p /user/cloudera/batch_tweets_indir
hadoop fs -mkdir -p /user/cloudera/batch_tweets_outdir

hadoop fs -copyFromLocal \
    /usr/share/doc/search*/examples/test-documents/sample-statuses-*.avro \
    /user/cloudera/batch_tweets_indir/

solrctl collection --deletedocs batch_tweets
hadoop --config /etc/hadoop/conf.cloudera.mapreduce1 \
    jar /usr/lib/solr/contrib/mr/search-mr-*-job.jar \
    org.apache.solr.hadoop.MapReduceIndexerTool \
    -D 'mapred.child.java.opts=-Xmx500m' \
    --log4j /usr/share/doc/search*/examples/solr-nrt/log4j.properties \
    --morphline-file /usr/share/doc/search*/examples/solr-nrt/test-morphlines/tutorialReadAvroContainer.conf \
    --output-dir hdfs://localhost.localdomain:8020/user/cloudera/batch_tweets_outdir \
    --verbose --go-live \
    --zk-host localhost.localdomain:2181/solr \
    --collection batch_tweets \
    hdfs://localhost.localdomain:8020/user/cloudera/batch_tweets_indir

