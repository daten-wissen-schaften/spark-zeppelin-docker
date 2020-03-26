FROM ubuntu:18.04

ARG ZEPPELIN_VERSION="0.8.1"
ARG SPARK_VERSION="2.4.5"
ARG HADOOP_VERSION="2.8.5"

LABEL maintainer="datenwissenschaften"
LABEL zeppelin.version=${ZEPPELIN_VERSION}
LABEL spark.version=${SPARK_VERSION}
LABEL hadoop.version=${HADOOP_VERSION}

########
# JAVA #
########

RUN apt-get -y update &&\
    apt-get -y install curl less &&\
    apt-get install -y openjdk-8-jdk &&\
    apt-get -y install vim

###################
# DOWNLOADS FIRST #
###################

ARG HADOOP_ARCHIVE=https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz
RUN mkdir /usr/local/hadoop
RUN curl -s ${HADOOP_ARCHIVE} | tar -xz -C /usr/local/hadoop --strip-components=1

ARG SPARK_ARCHIVE=https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-without-hadoop.tgz
RUN mkdir /usr/local/spark &&\
    mkdir /tmp/spark-events
RUN curl -s ${SPARK_ARCHIVE} | tar -xz -C /usr/local/spark --strip-components=1

ENV ZEPPELIN_HOME /usr/zeppelin/zeppelin-${ZEPPELIN_VERSION}-bin-all
RUN mkdir -p $ZEPPELIN_HOME \
  && mkdir -p $ZEPPELIN_HOME/logs \
  && mkdir -p $ZEPPELIN_HOME/run
RUN curl -s https://archive.apache.org/dist/zeppelin/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz | tar -xz -C /usr/zeppelin
RUN echo '{ "allow_root": true }' > /root/.bowerrc

##########
# HADOOP #
##########

ENV HADOOP_HOME /usr/local/hadoop
ENV PATH $PATH:${HADOOP_HOME}/bin

#########
# SPARK #
#########

ENV SPARK_HOME /usr/local/spark
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $PATH:${SPARK_HOME}/bin
COPY spark-defaults.conf ${SPARK_HOME}/conf/

############
# Zeppelin #
############

ENV ZEPPELIN_INTERPRETER_DEP_MVNREPO https://repo1.maven.org/maven2/
ENV ZEPPELIN_PORT 8080
EXPOSE $ZEPPELIN_PORT

RUN mkdir /notebook
ENV ZEPPELIN_CONF_DIR $ZEPPELIN_HOME/conf
ENV ZEPPELIN_NOTEBOOK_DIR /notebook

RUN mkdir /work
WORKDIR /work

ENTRYPOINT export SPARK_DIST_CLASSPATH=$(hadoop classpath); /usr/local/spark/sbin/start-history-server.sh; $ZEPPELIN_HOME/bin/zeppelin-daemon.sh start && bash