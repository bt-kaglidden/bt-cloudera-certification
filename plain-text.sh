#! /usr/bin/env bash

# This script creates a single-shard collection that will use Basis Technology's RLP in Solr
# and loads a set of artificial/generated tweets into
# the collection using the MapReduce indexer and GoLive

set -e

BT_BUILD=amd64-glibc25-gcc41
BT_COMMON_VER=20
BT_RLP_VER=7.10
BT_ROOT=/opt/rlp_7.10
DATASET=plain-text
SLF4J_VER=1.6.4

TEMPLATE_DIR=/home/cloudera/work/bt-cloudera-certification/config
SCHEMA_XML=$TEMPLATE_DIR/${DATASET}-schema.xml
SOLRCONFIG_XML=$TEMPLATE_DIR/${DATASET}-solrconfig.xml
INSTANCE_DIR=/home/cloudera/${DATASET}_configs

sudo mkdir -p /var/lib/cloudera-demovm

if [ ! -e /var/lib/cloudera-demovm/${DATASET}-generate.done ]; then
     solrctl instancedir --generate $INSTANCE_DIR
     cat $SCHEMA_XML | \
          sed -e "s|\[\[BT_ROOT\]\]|$BT_ROOT|g" \
          > $INSTANCE_DIR/conf/schema.xml
     # cat $SOLRCONFIG_XML | \
     #      sed -e "s|\[\[BT_BUILD\]\]|$BT_BUILD|g" | \
     #      sed -e "s|\[\[BT_COMMON_VER\]\]|$BT_COMMON_VER|g" | \
     #      sed -e "s|\[\[BT_RLP_VER\]\]|$BT_RLP_VER|g" | \
     #      sed -e "s|\[\[BT_ROOT\]\]|$BT_ROOT|g" | \
     #      sed -e "s|\[\[SLF4J_VER\]\]|$SLF4J_VER|g" \
     #      > $INSTANCE_DIR/conf/solrconfig.xml
    sudo touch /var/lib/cloudera-demovm/${DATASET}-generate.done
fi

if [ ! -e /var/lib/cloudera-demovm/${DATASET}-create-dir.done ]; then
    solrctl instancedir --create $DATASET /home/cloudera/${DATASET}_configs
    sudo touch /var/lib/cloudera-demovm/${DATASET}-create-dir.done
fi

if [ ! -e /var/lib/cloudera-demovm/${DATASET}-create-collection.done ]; then
    solrctl collection --create $DATASET -s 1
    sudo touch /var/lib/cloudera-demovm/${DATASET}-create-collection.done
fi

set +e
hadoop fs -rm -r -skipTrash /user/cloudera/${DATASET}_indir
hadoop fs -rm -r -skipTrash /user/cloudera/${DATASET}_outdir
set -e

hadoop fs -mkdir -p /user/cloudera/${DATASET}_indir
hadoop fs -mkdir -p /user/cloudera/${DATASET}_outdir

hadoop fs -copyFromLocal \
    /home/cloudera/work/bt-cloudera-certification/documents/*.txt \
    /user/cloudera/${DATASET}_indir/

solrctl collection --deletedocs $DATASET
hadoop --config /etc/hadoop/conf.cloudera.mapreduce1 \
    jar /usr/lib/solr/contrib/mr/search-mr-*-job.jar \
    org.apache.solr.hadoop.MapReduceIndexerTool \
    -D "mapred.child.java.opts=-Xmx500m -Dbt.root=${BT_ROOT} -DsharedLib=${BT_ROOT}/solrSharedLib" \
    --log4j /usr/share/doc/search*/examples/solr-nrt/log4j.properties \
    --morphline-file /home/cloudera/work/bt-cloudera-certification/ReadPlainText.conf \
    --output-dir hdfs://localhost.localdomain:8020/user/cloudera/${DATASET}_outdir \
    --verbose --go-live \
    --zk-host localhost.localdomain:2181/solr \
    --collection $DATASET \
    hdfs://localhost.localdomain:8020/user/cloudera/${DATASET}_indir
