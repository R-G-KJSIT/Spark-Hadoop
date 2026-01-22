# ---- Base image with Java already installed ----
FROM eclipse-temurin:17-jdk-jammy

# ---- Install Python & utilities ----
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        curl \
        bash \
        tini \
    && rm -rf /var/lib/apt/lists/*

# ---- Versions ----
ENV SPARK_VERSION=3.5.0
ENV HADOOP_VERSION=3
ENV SPARK_HOME=/opt/spark
ENV PYSPARK_PYTHON=python3
ENV PYSPARK_DRIVER_PYTHON=python3

# ---- Install Spark ----
RUN curl -fsSL https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
    | tar -xz -C /opt && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} ${SPARK_HOME}

ENV PATH="${SPARK_HOME}/bin:${PATH}"

# ---- Install PySpark ----
RUN pip3 install --no-cache-dir pyspark==${SPARK_VERSION}

WORKDIR /app

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["pyspark"]
