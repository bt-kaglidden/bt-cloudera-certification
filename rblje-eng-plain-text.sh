#! /usr/bin/env bash

# This script creates a single-shard collection that will use Basis Technology's
# RBL-JE English (ENG) analyzer in Solr.
# Loads a set of text documents into
# the collection using the MapReduce indexer and GoLive.

set -e

DATASET=rblje-eng-plain-text
PARCEL=/usr
HOST=localhost

BT_COMMON_VER=33
LUCENE_SOLR_VER=4_3
RBLJE_VER=2.3.0
RBLJE_ROOT=/opt/rblje-$RBLJE_VER
SLF4J_VER=1.7.5
BT_ROOT=$RBLJE_ROOT/rbl-je-$RBLJE_VER

ROOT_DIR=/home/$USER/basis/basis-cloudera-tests
TEMPLATE_DIR=$ROOT_DIR/config
SCHEMA_XML=$TEMPLATE_DIR/${DATASET}-schema.xml
SOLRCONFIG_XML=$TEMPLATE_DIR/${DATASET}-solrconfig.xml
INSTANCE_DIR=/home/$USER/${DATASET}_configs

sudo mkdir -p /var/lib/$USER-demovm

if [ ! -e /var/lib/$USER-demovm/${DATASET}-generate.done ]; then
     solrctl instancedir --generate $INSTANCE_DIR
     cat $SCHEMA_XML | \
          sed -e "s|\[\[bt.root\]\]|$BT_ROOT|g" \
          > $INSTANCE_DIR/conf/schema.xml
     cat $SOLRCONFIG_XML | \
          sed -e "s|\[\[BT_COMMON_VER\]\]|$BT_COMMON_VER|g" | \
          sed -e "s|\[\[LUCENE_SOLR_VER\]\]|$LUCENE_SOLR_VER|g" | \
          sed -e "s|\[\[RBLJE_VER\]\]|$RBLJE_VER|g" | \
          sed -e "s|\[\[RBLJE_ROOT\]\]|$RBLJE_ROOT|g" | \
          sed -e "s|\[\[SLF4J_VER\]\]|$SLF4J_VER|g" \
          > $INSTANCE_DIR/conf/solrconfig.xml
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
    $ROOT_DIR/documents/doc*.txt \
    /user/$USER/${DATASET}_indir/

hadoop fs -copyFromLocal \
    $ROOT_DIR/documents/English-*.txt \
    /user/$USER/${DATASET}_indir/

set +e
#
# TODO
# The files names here are specific to a proprietay Basis corpus.
# Change them to suit your test corpus.
#
hadoop fs -copyFromLocal \
    $ROOT_DIR/documents/eng-*.txt \
    /user/$USER/${DATASET}_indir/

hadoop fs -copyFromLocal \
    $ROOT_DIR/documents/*_ENG_*.txt \
    /user/$USER/${DATASET}_indir/
set -e

solrctl collection --deletedocs ${DATASET}
hadoop --config /etc/hadoop/conf.cloudera.yarn \
    jar ${PARCEL}/lib/solr/contrib/mr/search-mr-*-job.jar \
    org.apache.solr.hadoop.MapReduceIndexerTool \
    -D 'mapred.child.java.opts=-Xmx500m' \
    --log4j $PARCEL/share/doc/search*/examples/solr-nrt/log4j.properties \
    --morphline-file $ROOT_DIR/config/${DATASET}-morphlines.conf \
    --output-dir hdfs://$HOST:8020/user/$USER/${DATASET}_outdir \
    --verbose --go-live \
    --zk-host $HOST:2181/solr \
    --collection ${DATASET} \
    hdfs://$HOST:8020/user/$USER/${DATASET}_indir
