#!/bin/bash

set -e

SOURCES_DIR=/tmp/artifacts
SCRIPT_DIR=$(dirname $0)
SCRIPTS_DIR=${SCRIPT_DIR}/scripts

# Add strimzi user with UID 1001
# The user is in the group 0 to have access to the mounted volumes and storage
useradd -r -m -u 1001 -g 0 strimzi

mkdir $KAFKA_HOME
mkdir $STUNNEL_HOME
mkdir $S2I_HOME
mkdir $KAFKA_EXPORTER_HOME
mkdir $CRUISE_CONTROL_HOME
mkdir -p -m g+rw /usr/local/var/run/

chmod -R 0755 ${KAFKA_HOME}

# Copy contents of Cruise Control zip without the root dir
TMP=$(zipinfo -1  ${SOURCES_DIR}/cruise-control.zip | grep -oE '^[^/]+' | uniq)
unzip ${SOURCES_DIR}/cruise-control.zip
mv ${TMP}/* ${CRUISE_CONTROL_HOME}/libs/

# extract all the Kafka related scripts
unzip ${SOURCES_DIR}/strimzi-kafka-scripts.zip -d ${SCRIPTS_DIR}

# patch to remove "tini"
FILES=$(find ${SCRIPTS_DIR} -type f -name "*_run.sh")
for f in $FILES
do
  sed -i 's/\/usr\/bin\/tini -w -e 143 -- sh -c "${KAFKA_HOME}\/bin\/connect-distributed.sh \/tmp\/strimzi-connect.properties"/${KAFKA_HOME}\/bin\/connect-distributed.sh \/tmp\/strimzi-connect.properties/' $f
  sed -i 's/\/usr\/bin\/tini -w -e 143 -- sh -c "${KAFKA_HOME}\/bin\/kafka-server-start.sh \/tmp\/strimzi.properties"/${KAFKA_HOME}\/bin\/kafka-server-start.sh \/tmp\/strimzi.properties/' $f
  sed -i 's/\/usr\/bin\/tini -w -e 143 -- sh -c "${KAFKA_HOME}\/bin\/zookeeper-server-start.sh \/tmp\/zookeeper.properties"/${KAFKA_HOME}\/bin\/zookeeper-server-start.sh \/tmp\/zookeeper.properties/' $f
done

# NOTE: kafka folder alredy contains the s2i (so no need for a specific cp command)
cp -r ${SCRIPTS_DIR}/kafka/* ${KAFKA_HOME}/
chmod -R 755 ${KAFKA_HOME}

cp -r ${SCRIPTS_DIR}/stunnel/* ${STUNNEL_HOME}/
chmod -R 755 ${STUNNEL_HOME}

cp -r ${SCRIPTS_DIR}/kafka-exporter/* ${KAFKA_EXPORTER_HOME}/
chmod -R 755 ${KAFKA_EXPORTER_HOME}

cp -r ${SCRIPTS_DIR}/cruise-control/* ${CRUISE_CONTROL_HOME}/
chmod -R 755 ${CRUISE_CONTROL_HOME}
