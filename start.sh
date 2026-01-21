#!/bin/bash
set -e

# Start SSH daemon (REQUIRED for Hadoop)
service ssh start

# Start HDFS
start-dfs.sh

# Create Spark log dir
hdfs dfs -mkdir -p /spark-logs
hdfs dfs -chmod 777 /spark-logs

# Start YARN
start-yarn.sh

# Drop into PySpark
exec pyspark
