FROM apache/airflow:2.8.1-python3.10

# Switch to root to install packages
USER root

# Install Java + build tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-17-jdk \
        build-essential \
        libatlas-base-dev \
        gfortran \
        libpq-dev \
        libffi-dev \
        libssl-dev \
        curl \
        procps \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"

# Install Spark
ENV SPARK_VERSION=3.5.1
ENV HADOOP_VERSION=3
ENV SPARK_HOME=/usr/local/spark
ENV PATH="${SPARK_HOME}/bin:${JAVA_HOME}/bin:$PATH"

RUN curl -fsSL https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz | \
    tar -xz -C /usr/local && \
    mv /usr/local/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} ${SPARK_HOME}

# Switch back to airflow user
USER airflow

COPY requirements.txt /requirements.txt

RUN pip install --no-cache-dir -r /requirements.txt && \
    rm -rf ~/.cache/pip