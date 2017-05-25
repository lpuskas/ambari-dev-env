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
                hadoop hadoop-hdfs hadoop-libhdfs hadoop-yarn hadoop-mapreduce hadoop-client openssl \
                snappy snappy-devel lzo lzo-devel hadooplzo hadooplzo-native \
                zookeeper_2*-server zookeeper_2* \
                hbase_2* phoenix_2* \
                tez_2* \
                hive2_2* hive-hcatalog hive-webhcat mysql-server \
                pig_2* datafu_2* \
                oozie_2* oozie-client mysql-connector-java extjs \
                spark_2* livy_2* livy2_2* \
                spark2_2* \
                zeppelin_2* \
                sqoop_2* flume_2* \
                storm_2* \
                accumulo_2* \
                falcon_2* \
                knox_2* \
                kafka_2* \
                slider_2* \
                atlas-metadata_2* \
                ranger_2*-admin ranger-2*-usersync ranger_2*-tagsync ranger_2*-kms \
                && mv /etc/yum.repos.d/hdp.repo /etc/yum.repos.d/HDP.repo
