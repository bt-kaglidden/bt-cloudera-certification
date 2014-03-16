#! /usr/bin/env bash

# (Taken from original Cloudera "batch-tweets" sample.)
# This script creates a single-shard collection in Solr
# and loads a set of artificial/generated tweets into
# the collection using the MapReduce indexer and GoLive

set -e

DATASET=default-batch-tweets
PARCEL=/opt/cloudera/parcels/CDH
HOME=~$USER

sudo mkdir -p /var/lib/$USER-demovm

if [ ! -e /var/lib/$USER-demovm/${DATASET}-generate.done ]; then
    solrctl instancedir --generate $HOME/${DATASET}_configs
    cp -f $PARCEL/share/doc/search*/examples/solr-nrt/collection1/conf/schema.xml $HOME/${DATASET}_configs/conf/
    sudo touch /var/lib/$USER-demovm/${DATASET}-generate.done
fi

if [ ! -e /var/lib/$USER-demovm/${DATASET}-create-dir.done ]; then
    solrctl instancedir --create ${DATASET} $HOME/${DATASET}_configs
    sudo touch /var/lib/$USER-demovm/${DATASET}-create-dir.done
fi

if [ ! -e /var/lib/$USER-demovm/${DATASET}-create-collection.done ]; then
    solrctl collection --create ${DATASET} -s 1
    sudo touch /var/lib/$USER-demovm/${DATASET}-create-collection.done
fi

set +e
hadoop fs -rm -r -skipTrash /user/$USER/${DATASET}_indir
hadoop fs -rm -r -skipTrash /user/$USER/${DATASET}_outdir
set -e

hadoop fs -mkdir -p /user/$USER/${DATASET}_indir
hadoop fs -mkdir -p /user/$USER/${DATASET}_outdir

hadoop fs -copyFromLocal \
    $PARCEL/share/doc/search*/examples/test-documents/sample-statuses-*.avro \
    /user/$USER/${DATASET}_indir/

solrctl collection --deletedocs ${DATASET}
hadoop --config /etc/hadoop/conf.$USER.mapreduce1 \
    jar /usr/lib/solr/contrib/mr/search-mr-*-job.jar \
    org.apache.solr.hadoop.MapReduceIndexerTool \
    -D 'mapred.child.java.opts=-Xmx500m' \
    --log4j $PARCEL/share/doc/search*/examples/solr-nrt/log4j.properties \
    --morphline-file $PARCEL/share/doc/search*/examples/solr-nrt/test-morphlines/tutorialReadAvroContainer.conf \
    --output-dir hdfs://localhost.localdomain:8020/user/$USER/${DATASET}_outdir \
    --verbose --go-live \
    --zk-host localhost.localdomain:2181/solr \
    --collection ${DATASET} \
    hdfs://localhost.localdomain:8020/user/$USER/${DATASET}_indir

