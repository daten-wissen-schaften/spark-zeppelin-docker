FROM ubuntu:18.04

ARG ZEPPELIN_VERSION="0.10.0"
ARG SPARK_VERSION="3.0.1"
ARG HADOOP_VERSION="3.2.1"
ARG JAVA_VERSION="1.8.0"

LABEL maintainer="datenwissenschaften"
LABEL zeppelin.version=${ZEPPELIN_VERSION}
LABEL spark.version=${SPARK_VERSION}
LABEL hadoop.version=${HADOOP_VERSION}

#################
# JAVA & PYTHON #
#################

RUN apt-get -y update &&\
    apt-get -y install wget gnupg software-properties-common

RUN wget --quiet -O - https://apt.corretto.aws/corretto.key | apt-key add - &&\
    add-apt-repository 'deb https://apt.corretto.aws stable main'

RUN apt-get -y update &&\
    apt-get -y install curl less psmisc vim unzip &&\
    apt-get -y install java-${JAVA_VERSION}-amazon-corretto-jdk &&\
    apt-get -y install python3-pip &&\
    apt-get -y install maven &&\
    apt-get -y install nodejs &&\
    apt-get -y install npm &&\
    python3 -m pip install findspark &&\
    python3 -m pip install Cython &&\
    python3 -m pip install numpy &&\
    python3 -m pip install pandas

ENV PYSPARK_PYTHON /usr/bin/python3

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

ENV JAVA_HOME /usr/lib/jvm/java-${JAVA_VERSION}-amazon-corretto

RUN java -version &&\
    python -v

#############
# DOWNLOADS #
#############

ARG HADOOP_ARCHIVE=https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz
RUN mkdir /usr/local/hadoop &&\
    curl -s ${HADOOP_ARCHIVE} | tar -xz -C /usr/local/hadoop --strip-components=1

ARG SPARK_ARCHIVE=https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-without-hadoop.tgz
RUN mkdir /usr/local/spark &&\
    mkdir /tmp/spark-events &&\
    curl -s ${SPARK_ARCHIVE} | tar -xz -C /usr/local/spark --strip-components=1

ENV ZEPPELIN_HOME /usr/local/zeppelin
RUN curl -s https://archive.apache.org/dist/zeppelin/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz | tar -xz -C /usr/local/ &&\
    echo '{ "allow_root": true }' > /root/.bowerrc &&\
    echo "unsafe-perm=true" > ~/.npmrc &&\
    mv /usr/local/zeppelin-${ZEPPELIN_VERSION}-bin-all ${ZEPPELIN_HOME} &&\
    mkdir -p ${ZEPPELIN_HOME}/logs &&\
    mkdir -p ${ZEPPELIN_HOME}/run


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
ENV PATH $PATH:${SPARK_HOME}/bin
COPY spark-defaults.conf ${SPARK_HOME}/conf/

############
# ZEPPELIN #
############

ENV ZEPPELIN_INTERPRETER_DEP_MVNREPO https://repo1.maven.org/maven2/
ENV ZEPPELIN_ADDR 0.0.0.0
ENV ZEPPELIN_PORT 8080
EXPOSE $ZEPPELIN_PORT

RUN mkdir -p /work/zeppelin/conf
RUN mkdir -p /work/zeppelin/notebook
RUN mkdir -p /work/zeppelin/logs

ENV ZEPPELIN_CONF_DIR /work/zeppelin/conf
ENV ZEPPELIN_NOTEBOOK_DIR /work/zeppelin/notebook
ENV ZEPPELIN_LOG_DIR /work/zeppelin/logs

COPY log4j.properties /work/zeppelin/conf

########
# LOGS #
########

RUN npm i frontail -g

WORKDIR /work

ENTRYPOINT export SPARK_DIST_CLASSPATH=$(hadoop classpath); /usr/local/spark/sbin/start-history-server.sh; $ZEPPELIN_HOME/bin/zeppelin-daemon.sh start; frontail /work/zeppelin/logs/*.log && bash
