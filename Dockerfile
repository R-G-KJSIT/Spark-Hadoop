# ---- Base image ----
FROM python:3.11-slim

# ---- Versions ----
ENV SPARK_VERSION=3.5.0
ENV HADOOP_VERSION=3
ENV SPARK_HOME=/opt/spark
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# ---- Install system dependencies ----
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        openjdk-17-jdk \
        bash \
        tini \
    && rm -rf /var/lib/apt/lists/*

# ---- Download and install Spark (with Hadoop) ----
RUN curl -fsSL https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
    | tar -xz -C /opt && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} ${SPARK_HOME}

# ---- Environment variables ----
ENV PATH="${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${PATH}"
ENV PYSPARK_PYTHON=python3
ENV PYSPARK_DRIVER_PYTHON=python3

# ---- Install PySpark (optional but recommended) ----
RUN pip install --no-cache-dir pyspark==${SPARK_VERSION}

# ---- Create working directory ----
WORKDIR /app

# ---- Default entrypoint ----
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["pyspark"]
