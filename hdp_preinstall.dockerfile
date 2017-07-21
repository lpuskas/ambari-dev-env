#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

FROM ambari/docker-dev:latest

ADD hdp.repo /etc/yum.repos.d/hdp.repo


RUN yum -d 0 -e 0  -y install yum-skip-broken && yum update -y --skip-broken && \
    yum -d 0 -e 0 -y install --skip-broken \
                accumulo-2* \
                atlas-metadata-2* \
                datafu-2* \
                falcon-2* \
                flume-2* \
                hadoop hadoop-2* hadoop-client hadoop-hdfs hadoop-libhdfs hadoop-lzo hadoop-lzo-native hadoop-mapreduce hadoop-yarn hadoop_2* hadooplzo-2* \
                hawq \
                hbase-2* \
                hcatalog hive-2* hive-hcatalog hive-webhcat hive2-2* hive_2* webhcat-tar-hive webhcat-tar-pig \
                httpd \
                kafka-2* \
                knox-2* \
                libhdfs0 libhdfs0-2* libhdfs0-dev liblzo2-2 libsnappy-dev libsnappy1 libsnappy1* libsnappy1v5* libtirpc-devel libxml2-utils \
                spark_2* spark2_2* \
                livy-2* livy2-2* livy2_2* \
                lzo mahout \
                mysql mysql-client mysql-community-release mysql-community-server mysql-connector-java mysql-server \
                oozie-2* oozie-client \
                phoenix-2* \
                pig-2* \
                postgresql-* \
                pxf-* \
                ranger-2* \
                rpcbind \
                rrdcached \
                slider-2* \
                snappy snappy-devel \
                sqoop-2* \
                storm-2* \
                superset-2* \
                tez-2* tez-hive2-2* tez_hive2_2* \
                viprfs-client \
                zeppelin-2* \
                zip \
                zookeeper-2* zookeeper_2* \
                && mv /etc/yum.repos.d/hdp.repo /etc/yum.repos.d/HDP.repo
