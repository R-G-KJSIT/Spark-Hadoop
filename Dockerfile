FROM eclipse-temurin:17-jdk-jammy

# ---- Versions ----
ENV HADOOP_VERSION=3.3.6
ENV SPARK_VERSION=3.5.0

ENV HADOOP_HOME=/opt/hadoop
ENV SPARK_HOME=/opt/spark
ENV JAVA_HOME=/opt/java/openjdk

# ---- PATH (Java first, Hadoop scripts are picky) ----
ENV PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$PATH

# ---- Allow Hadoop/YARN to run as root (Docker/dev only) ----
ENV HDFS_NAMENODE_USER=root
ENV HDFS_DATANODE_USER=root
ENV HDFS_SECONDARYNAMENODE_USER=root
ENV YARN_RESOURCEMANAGER_USER=root
ENV YARN_NODEMANAGER_USER=root

# ---- Install OS deps ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    curl \
    openssh-server \
    ssh \
    rsync \
    bash \
    tini \
 && rm -rf /var/lib/apt/lists/*

# ---- SSH setup for Hadoop ----
RUN mkdir -p /var/run/sshd && \
    ssh-keygen -A && \
    echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

# ---- Install Hadoop ----
RUN curl -fsSL https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
 | tar -xz -C /opt \
 && mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME}

# ---- Tell Hadoop where Java lives (CRITICAL FIX) ----
RUN sed -i "s|^# export JAVA_HOME=.*|export JAVA_HOME=${JAVA_HOME}|" \
    ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh

# ---- Install Spark (without bundled Hadoop) ----
RUN curl -fsSL https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-without-hadoop.tgz \
 | tar -xz -C /opt \
 && mv /opt/spark-${SPARK_VERSION}-bin-without-hadoop ${SPARK_HOME}

# ---- Hadoop data dirs ----
RUN mkdir -p \
    /hadoop/dfs/name \
    /hadoop/dfs/data \
    /hadoop/yarn/local \
    /hadoop/yarn/logs

# ---- Hadoop config ----
RUN printf '<?xml version="1.0"?>\n\
<configuration>\n\
  <property>\n\
    <name>fs.defaultFS</name>\n\
    <value>hdfs://localhost:9000</value>\n\
  </property>\n\
</configuration>' > ${HADOOP_HOME}/etc/hadoop/core-site.xml

RUN printf '<?xml version="1.0"?>\n\
<configuration>\n\
  <property>\n\
    <name>dfs.replication</name>\n\
    <value>1</value>\n\
  </property>\n\
  <property>\n\
    <name>dfs.namenode.name.dir</name>\n\
    <value>file:/hadoop/dfs/name</value>\n\
  </property>\n\
  <property>\n\
    <name>dfs.datanode.data.dir</name>\n\
    <value>file:/hadoop/dfs/data</value>\n\
  </property>\n\
</configuration>' > ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml

RUN printf '<?xml version="1.0"?>\n\
<configuration>\n\
  <property>\n\
    <name>yarn.nodemanager.aux-services</name>\n\
    <value>mapreduce_shuffle</value>\n\
  </property>\n\
</configuration>' > ${HADOOP_HOME}/etc/hadoop/yarn-site.xml

RUN printf '<?xml version="1.0"?>\n\
<configuration>\n\
  <property>\n\
    <name>mapreduce.framework.name</name>\n\
    <value>yarn</value>\n\
  </property>\n\
</configuration>' > ${HADOOP_HOME}/etc/hadoop/mapred-site.xml

# ---- Spark config (run on YARN) ----
RUN printf 'spark.master yarn\n\
spark.eventLog.enabled true\n\
spark.eventLog.dir hdfs:///spark-logs\n' > ${SPARK_HOME}/conf/spark-defaults.conf

# ---- PySpark ----
RUN pip3 install --no-cache-dir pyspark==${SPARK_VERSION}

# ---- Format HDFS (single-node dev setup) ----
RUN hdfs namenode -format

# ---- Startup script ----
COPY start.sh /start.sh
RUN chmod +x /start.sh

# ---- Ports ----
EXPOSE 9870 8088 4040

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/start.sh"]
