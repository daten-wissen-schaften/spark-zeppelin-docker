FROM ubuntu:bionic

ARG ZEPPELIN_VERSION="0.9.0"
ARG SPARK_VERSION="3.0.1"
ARG HADOOP_VERSION="3.2.1"
ARG LIVY_VERSION="0.7.1-incubating"
ARG JAVA_VERSION="1.8.0"

LABEL maintainer="datenwissenschaften"
LABEL zeppelin.version=${ZEPPELIN_VERSION}
LABEL spark.version=${SPARK_VERSION}
LABEL hadoop.version=${HADOOP_VERSION}
LABEL livy.version=${LIVY_VERSION}

#################
# JAVA & PYTHON #
#################

RUN apt-get -y update &&\
    apt-get -y install wget gnupg software-properties-common

RUN wget --quiet -O - https://apt.corretto.aws/corretto.key | apt-key add - &&\
    add-apt-repository 'deb https://apt.corretto.aws stable main'

RUN apt-get -y update &&\
    apt-get -y install curl less psmisc &&\
    apt-get -y install vim &&\
    apt-get -y install unzip &&\
    apt-get -y install java-${JAVA_VERSION}-amazon-corretto-jdk &&\
    apt-get -y install python3-pip

RUN python3 -m pip install findspark &&\
    python3 -m pip install Cython &&\
    python3 -m pip install numpy &&\
    python3 -m pip install pandas

ENV PYSPARK_PYTHON /usr/bin/python3

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

#############
# DOWNLOADS #
#############

ARG HADOOP_ARCHIVE=https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz
RUN mkdir /usr/local/hadoop  &&\
    curl -s ${HADOOP_ARCHIVE} | tar -xz -C /usr/local/hadoop --strip-components=1

ARG SPARK_ARCHIVE=https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-without-hadoop.tgz
RUN mkdir /usr/local/spark &&\
    mkdir /tmp/spark-events &&\
    curl -s ${SPARK_ARCHIVE} | tar -xz -C /usr/local/spark --strip-components=1

ARG LIVY_ARCHIVE=https://ftp.halifax.rwth-aachen.de/apache/incubator/livy/${LIVY_VERSION}/apache-livy-${LIVY_VERSION}-bin.zip
RUN curl -o livy.zip ${LIVY_ARCHIVE} &&\
    unzip livy.zip -d /usr/local &&\
    rm livy.zip &&\
    mv /usr/local/apache-livy-${LIVY_VERSION}-bin /usr/local/livy

ENV ZEPPELIN_HOME /usr/zeppelin/zeppelin-${ZEPPELIN_VERSION}-bin-all
RUN mkdir -p $ZEPPELIN_HOME &&\
    mkdir -p $ZEPPELIN_HOME/logs &&\
    mkdir -p $ZEPPELIN_HOME/run &&\
    curl -s https://archive.apache.org/dist/zeppelin/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz | tar -xz -C /usr/zeppelin &&\
    echo '{ "allow_root": true }' > /root/.bowerrc &&\
    echo "unsafe-perm=true" > ~/.npmrc

##########
# HADOOP #
##########

ENV HADOOP_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV HADOOP_COMMON_LIB_NATIVE_DIR $HADOOP_HOME/lib/native
ENV HADOOP_OPTS "-Djava.library.path=$HADOOP_HOME/lib"
ENV PATH $PATH:${HADOOP_HOME}/bin

#########
# SPARK #
#########

ENV SPARK_HOME /usr/local/spark
ENV JAVA_HOME /usr/lib/jvm/java-${JAVA_VERSION}-amazon-corretto
ENV PATH $PATH:${SPARK_HOME}/bin
COPY spark-defaults.conf ${SPARK_HOME}/conf/

########
# LIVY #
########

ENV LIVY_HOME /usr/local/livy
COPY livy.conf ${LIVY_HOME}/conf/

############
# ZEPPELIN #
############

ENV ZEPPELIN_INTERPRETER_DEP_MVNREPO https://repo1.maven.org/maven2/
ENV ZEPPELIN_ADDR 0.0.0.0
ENV ZEPPELIN_PORT 8080
EXPOSE $ZEPPELIN_PORT

RUN mkdir /notebook
ENV ZEPPELIN_CONF_DIR $ZEPPELIN_HOME/conf
ENV ZEPPELIN_NOTEBOOK_DIR /notebook

RUN mkdir /work
WORKDIR /work

ENTRYPOINT export SPARK_DIST_CLASSPATH=$(hadoop classpath); /usr/local/spark/sbin/start-history-server.sh; $LIVY_HOME/bin/livy-server start; $ZEPPELIN_HOME/bin/zeppelin-daemon.sh start && bash
