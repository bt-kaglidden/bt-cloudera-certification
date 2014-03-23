#! /usr/bin/env bash

# (Taken from original Cloudera "batch-tweets" sample.)
# This script creates a single-shard collection in Solr
# and loads a set of artificial/generated tweets into
# the collection using the MapReduce indexer and GoLive

set -e

DATASET=default-batch-tweets
PARCEL=/opt/cloudera/parcels/CDH

sudo mkdir -p /var/lib/$USER-demovm

if [ ! -e /var/lib/$USER-demovm/${DATASET}-generate.done ]; then
    solrctl instancedir --generate /home/$USER/${DATASET}_configs
    cp -f $PARCEL/share/doc/search*/examples/solr-nrt/collection1/conf/schema.xml /home/$USER/${DATASET}_configs/conf/
    sudo touch /var/lib/$USER-demovm/${DATASET}-generate.done
fi

if [ ! -e /var/lib/$USER-demovm/${DATASET}-create-dir.done ]; then
    solrctl instancedir --create ${DATASET} /home/$USER/${DATASET}_configs
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
hadoop --config /etc/hadoop/conf.cloudera.yarn\
    jar ${PARCEL}/lib/solr/contrib/mr/search-mr-*-job.jar \
    org.apache.solr.hadoop.MapReduceIndexerTool \
    -D 'mapred.child.java.opts=-Xmx500m' \
    --log4j $PARCEL/share/doc/search*/examples/solr-nrt/log4j.properties \
    --morphline-file $PARCEL/share/doc/search*/examples/solr-nrt/test-morphlines/tutorialReadAvroContainer.conf \
    --output-dir hdfs://ec2-54-197-48-181.compute-1.amazonaws.com:8020/user/$USER/${DATASET}_outdir \
    --verbose --go-live \
    --zk-host ec2-54-197-48-181.compute-1.amazonaws.com:2181/solr \
    --collection ${DATASET} \
    hdfs://ec2-54-197-48-181.compute-1.amazonaws.com:8020/user/$USER/${DATASET}_indir

