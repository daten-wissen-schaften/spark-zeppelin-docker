# spark-zeppelin-docker 

This docker image provides a local *spark* installation with *zeppelin*, *livy* and a running *spark-history-server*.
It is uploaded in [dockerhub](https://hub.docker.com/r/datenwissenschaften/spark-zeppelin-docker/) in a public repository.

## Components

- Spark version="3.0.1"
- Zeppelin version="0.9.0"
- Hadoop version="3.2.1"
- Livy version="0.8.0-SNAPSHOT"
- Amazon Coretto JDK version="1.8.0"

## Start the container with example notebooks

```
  docker run -it -p 18080:18080 -p 8088:8080 -p 8998:8998 -d datenwissenschaften/spark-zeppelin-docker
```

## Mount local notebooks

```
  docker run -it -p 18080:18080 -p 8088:8080 -p 8998:8998 -v $PWD/notebook:/notebook -d datenwissenschaften/spark-zeppelin-docker
```

## Open Zeppelin and Spark History Server  

In your local browser 
- Zeppelin: http://localhost:8088/#/
- Spark History Server: http://localhost:18080/?showIncomplete=true
- Livy Server: http://localhost:8998/ui

Probably, you have to wait roughly 10 second until zeppelin daemon has been started, right after starting the container.

## Spark-App
 
### Copy your spark jar to docker container

Start another shell session and copy the jar-file into the docker container.
Following command copies it into your latest started container.

```
docker cp <your-jar-file.jar> $(docker ps -l -q):/work/
```

###  Run spark job

Go back to container session. You should be connected as root in the docker container:

```
cd /work
spark-submit --class <your-class-name-with-package> \
      <your-jar-file.jar> \
      [<your-program-parameters>]
```

## Custom build

To make a custom build with custom jars for Apache Spark, Zeppelin and Livy inherit with a new Dockerfile:

```
FROM datenwissenschaften/spark-zeppelin-docker

COPY target/custom.jar ${SPARK_HOME}/jars/
COPY target/own.jar ${SPARK_HOME}/jars/
COPY target/library.jar ${SPARK_HOME}/jars/

RUN python3 -m pip install numpy
RUN python3 -m pip install pandas
```