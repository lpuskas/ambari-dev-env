#!/usr/bin/env bash
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distrbuted under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.


ambari-dev-server-start() {
 export CONTAINER_IP=$(hostname -i)

 echo "Container IP address": $CONTAINER_IP

 echo "Refreshing stack hash codes and starting the application.."
 python /ambari/ambari-server/src/main/python/ambari-server.py refresh-stack-hash

 cp /ambari/ambari-server/conf/unix/ambari-sudo.sh /usr/local/sbin/ambari-sudo.sh
 chmod 777 /usr/local/sbin/ambari-sudo.sh

 java \
    -Dfile.encoding=UTF-8 \
    -Dlog4j.configuration=file:/ambari-server-conf/log4j.properties \
    -Djava.security.auth.login.config=/ambari-server-conf/krb5JAASLogin.conf \
    -DskipDatabaseConsistencyValidation \
    -Xmx2048m -Xms256m -XX:MaxPermSize=128m -XX:+CMSClassUnloadingEnabled \
    -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=50100 \
    -classpath $(cat /tmp/cp.txt):target/classes:/ambari-server-conf:/ambari/ambari-views/target \
    org.apache.ambari.server.controller.AmbariServer &

  SERVER_PID="$!"
  echo "Ambari server PID: [ $SERVER_PID ]"
  if [ ! -d "/var/run/ambari-server" ]
  then
    echo "Creating folder: /var/run/ambari-server"
    mkdir /var/run/ambari-server
  fi

  echo $SERVER_PID > /var/run/ambari-server/ambari-server.pid

  # tests for the existence of the process
  kill -0 $SERVER_PID 2>/dev/null
  server_runs="$?"

  while [ "$server_runs" -lt 1 ]
  do
    kill -0 $SERVER_PID 2>/dev/null
    server_runs="$?"
    if [ "$server_runs" -lt 1 ];
    then
      echo "Ambari Server is running"
      sleep 10
    else
      echo "Ambari Server stopped"
    fi

  done

  echo "exiting  ambari server $1"
}

ambari-setup () {
  if [ "$1" = "local" ]
    then
      echo "Installing from local target ..."
      yum -y install /ambari/ambari-server/target/rpm/ambari-server/RPMS/x86_64/ambari-server-*.x86_64.rpm
  else
      cd /etc/yum.repos.d
      wget $1
      yum -y install ambari-server
  fi
  ambari-server setup -s
}

ambari-server-start() {
  ambari-server start -g
  while true; do
    sleep 3
    tail -f /var/log/ambari-server/ambari-server.log
  done
}

main() {
  echo "Registering $HOSTNAME consul node with consul cluster"
  consul agent -config-file=/etc/consul.json -server -bootstrap -node=$(hostname -s) -advertise=$(hostname -i) -client=0.0.0.0 -recursor=8.8.8.8 -recursor=10.10.1.20 -recursor=10.42.1.20 &

  if [ ! -n "$1" ]
    then
      source /scripts/common-server-functions.sh
      cd /ambari/ambari-server
      generate-classpath
      set-path
      setup-security-config
      create-version-file
      copy-libs-to-resources-dir
      ambari-dev-server-start
  else
    ambari-setup $1
    ambari-server-start
  fi
}

main "$@"
