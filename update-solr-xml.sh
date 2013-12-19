#! /bin/bash -ue

# This updates zookeeper's copy of solr.xml to include the Basis
# lib directory as a sharedLib.

SOLR_XML='<solr>

  <solrcloud>
    <str name="host">${host:}</str>
    <int name="hostPort">${solr.port:8983}</int>
    <str name="hostContext">${hostContext:solr}</str>
    <int name="zkClientTimeout">${zkClientTimeout:15000}</int>
    <bool name="genericCoreNodeNames">${genericCoreNodeNames:true}</bool>
    <str name="sharedLib">${sharedLib:}</str>
  </solrcloud>

  <shardHandlerFactory name="shardHandlerFactory"
    class="HttpShardHandlerFactory">
    <int name="socketTimeout">${socketTimeout:0}</int>
    <int name="connTimeout">${connTimeout:0}</int>
  </shardHandlerFactory>

</solr>'

/usr/lib/zookeeper/bin/zkCli.sh set /solr/solr.xml "'$SOLR_XML'"