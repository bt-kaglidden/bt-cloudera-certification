#! /usr/bin/env bash

# This script creates a single-shard collection that will use Basis Technology's
# RBL-JE Spanish (SPA) analyzer in Solr.
# Loads a set of text documents into
# the collection using the MapReduce indexer and GoLive.

set -e

BT_COMMON_VER=21
DATASET=rblje-spa-plain-text
LUCENE_SOLR_VER=4_3
RBLJE_VER=2.1.0
RBLJE_ROOT=/opt/rblje-$RBLJE_VER
SLF4J_VER=1.6.3
LICENSE_FILE_PATH=$RBLJE_ROOT/rbl-je-$RBLJE_VER/licenses/rlp-license.xml

ROOT_DIR=/home/cloudera/work/basis-cloudera-tests
TEMPLATE_DIR=$ROOT_DIR/config
SCHEMA_XML=$TEMPLATE_DIR/${DATASET}-schema.xml
SOLRCONFIG_XML=$TEMPLATE_DIR/${DATASET}-solrconfig.xml
INSTANCE_DIR=/home/cloudera/${DATASET}_configs

sudo mkdir -p /var/lib/cloudera-demovm

if [ ! -e /var/lib/cloudera-demovm/${DATASET}-generate.done ]; then
     solrctl instancedir --generate $INSTANCE_DIR
     cat $SCHEMA_XML | \
          sed -e "s|\[\[bt.license.path\]\]|$LICENSE_FILE_PATH|g" | \
          sed -e "s|\[\[bt.model.directory\]\]|$RBLJE_ROOT/rbl-je-$RBLJE_VER/models|g" | \
          sed -e "s|\[\[bt.dictionary.directory\]\]|$RBLJE_ROOT/rbl-je-$RBLJE_VER/dicts|g" \
          > $INSTANCE_DIR/conf/schema.xml
     cat $SOLRCONFIG_XML | \
          sed -e "s|\[\[BT_COMMON_VER\]\]|$BT_COMMON_VER|g" | \
          sed -e "s|\[\[LUCENE_SOLR_VER\]\]|$LUCENE_SOLR_VER|g" | \
          sed -e "s|\[\[RBLJE_VER\]\]|$RBLJE_VER|g" | \
          sed -e "s|\[\[RBLJE_ROOT\]\]|$RBLJE_ROOT|g" | \
          sed -e "s|\[\[SLF4J_VER\]\]|$SLF4J_VER|g" \
          > $INSTANCE_DIR/conf/solrconfig.xml
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

#
# TODO
# The files names here are specific to a proprietay Basis corpus.
# Change them to suit your test corpus.
#
hadoop fs -copyFromLocal \
    $ROOT_DIR/documents/*_SPA_*.txt \
    /user/cloudera/${DATASET}_indir/

solrctl collection --deletedocs $DATASET
hadoop --config /etc/hadoop/conf.cloudera.mapreduce1 \
    jar /usr/lib/solr/contrib/mr/search-mr-*-job.jar \
    org.apache.solr.hadoop.MapReduceIndexerTool \
    -D "mapred.child.java.opts=-Xmx500m" \
    --log4j /usr/share/doc/search*/examples/solr-nrt/log4j.properties \
    --morphline-file $ROOT_DIR/config/${DATASET}-morphlines.conf \
    --output-dir hdfs://localhost.localdomain:8020/user/cloudera/${DATASET}_outdir \
    --verbose --go-live \
    --zk-host localhost.localdomain:2181/solr \
    --collection $DATASET \
    hdfs://localhost.localdomain:8020/user/cloudera/${DATASET}_indir
