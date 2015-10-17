#!/usr/bin/env bash +a
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


check-dev-env(){

: ${HOME?"Please set the variable in the .dev-profile file"}
: ${DEV_DOCKER_IMAGE:=ambari/docker-dev}
: ${DEV_AMBARI_PROJECT_DIR?"Please set the variable in the .dev-profile file"}
: ${DEV_AMBARI_SERVER_CONFIG_DIR:="$DEV_PROJECT_PATH/conf"}
: ${DEV_NUMBER_OF_AGENTS:=3}
: ${DEV_AMBARI_SERVER_VERSION:="2.0.0.0"}
: ${DEV_AMBARI_SERVER_DEBUG_PORT:=5005}
: ${DEV_KERBEROS_DOCKER_IMAGE:=sequenceiq/kerberos}
: ${DEV_KERBEROS_REALM:=AMBARI.APACHE.ORG}
: ${DEV_KERBEROS_DOMAIN_REALM:=kerberos-server}
: ${DEV_AMBARI_DB_DOCKER_IMAGE:=sequenceiq/ambari-dev-psql}
: ${DEV_YUM_CACHE_DIR:="$HOME/tmp/docker/cache/yum"}
}

set-project-path() {
  pushd "$(dirname "$0")" > /dev/null
  DEV_PROJECT_PATH=`pwd`
  popd > /dev/null
}

show-dev-env(){
  echo "Development environement variables: "
  for i in ${!DEV_*}
  do
    eval val=\$$i
    echo $i = $val
  done
}

generate-dev-env-profile() {
  if [ ! -f .dev-profile ]
    then
      cat > .dev-profile <<EOF
# The locatin of the ambari project on the host
# This entry is mandatory!
DEV_AMBARI_PROJECT_DIR=

# Number of ambari agents to start
DEV_NUMBER_OF_AGENTS=3

# Custom version of ambari server
#DEV_AMBARI_SERVER_VERSION=

# Debug port of ambari server
DEV_AMBARI_SERVER_DEBUG_PORT=5005

# The location of the Yum cache
#DEV_YUM_CACHE_DIR


EOF
echo "Please fill the newly generated .dev-profile in the current directory"
exit 1;
   else
    source .dev-profile
    show-dev-env
  fi
}

check-dev-docker-image() {
  if docker history -q $DEV_DOCKER_IMAGE 2>&1 >/dev/null; then
    echo "$DEV_DOCKER_IMAGE image found."
  else
    docker build -t $DEV_DOCKER_IMAGE .
  fi
}

build-ambari-agent-rpm() {
  if [ "$(ls $DEV_AMBARI_PROJECT_DIR/ambari-agent/target/rpm/ambari-agent/RPMS/x86_64 | wc -l)" -ge "1" ]
  then
    echo "Ambari agent rpm found."
  else
    echo "Building Ambari Agent rpm ..."
    docker run \
      --rm --privileged \
      -v $DEV_AMBARI_PROJECT_DIR/:/ambari \
      -v $HOME/.m2/:/root/.m2 --entrypoint=/bin/bash \
      -w /ambari/ambari-agent \
      $DEV_DOCKER_IMAGE \
      -c 'mvn clean package rpm:rpm -Dstack.distribution=HDP -Dmaven.clover.skip=true -Dfindbugs.skip=true -DskipTests -Dpython.ver="python >= 2.6"'
  fi
}

gen-database-container-yml(){
  CONTAINER_NAME=ambari-db
  cat >> $1<<EOF
$CONTAINER_NAME:
  privileged: true
  container_name: $CONTAINER_NAME
  hostname: $CONTAINER_NAME
  ports:
    - "5432:5432"
  environment:
    - POSTGRES_USER=ambari
    - POSTGRES_PASSWORD=bigdata
  volumes:
    - "/var/lib/boot2docker/ambari:/var/lib/postgresql/data"
  image: $DEV_AMBARI_DB_DOCKER_IMAGE

EOF
}

gen-local-db-container-yml(){
  CONTAINER_NAME=ambari-db
  cat >> $1<<EOF
$CONTAINER_NAME:
  privileged: true
  container_name: $CONTAINER_NAME
  hostname: $CONTAINER_NAME
  ports:
    - "5432:5432"
  environment:
    - POSTGRES_USER=ambari
    - POSTGRES_PASSWORD=bigdata
  entrypoint: /scripts/reload-schema.sh
  volumes:
    - "$DEV_AMBARI_PROJECT_DIR/:/ambari"
    - "$DEV_PROJECT_PATH/container:/scripts"
  image: postgres:9.4

EOF
}
gen-ambari-server-yml(){
  CONTAINER_NAME=ambari-server
  cat >> $1<<EOF
$CONTAINER_NAME:
  privileged: true
  container_name: $CONTAINER_NAME
  hostname: $CONTAINER_NAME
  ports:
    - "$DEV_AMBARI_SERVER_DEBUG_PORT:50100"
    - "8080:8080"
  environment:
    - SERVER_VERSION=$DEV_AMBARI_SERVER_VERSION
  volumes:
    - "$DEV_AMBARI_PROJECT_DIR/:/ambari"
    - "$HOME/.m2/:/root/.m2"
    - "$DEV_PROJECT_PATH/container:/scripts"
    - "$DEV_AMBARI_SERVER_CONFIG_DIR/:/ambari-server-conf"
    - "$DEV_AMBARI_SERVER_CONFIG_DIR/krb5.conf:/etc/krb5.conf"
    - "$HOME/tmp/docker/ambari-server/tmp:/tmp/ambari-server"
    - "$HOME/tmp/docker/ambari-server/logs:/logs/ambari-server"
    - "$HOME/tmp/docker/ambari-server/keytabs:/keytabs/ambari-server"
    - "$HOME/tmp/docker/ambari-server/ssl-keys:/ssl-keys/ambari-server"
  image: $DEV_DOCKER_IMAGE
  entrypoint: ["/bin/sh"]
  command: -c '/scripts/runServer.sh'

EOF
}

gen-ambari-agent-yml(){
  CONTAINER_NAME=ambari-agent-$i
  cat <<EOF >> $1
$CONTAINER_NAME:
  privileged: true
  container_name: $CONTAINER_NAME
  hostname: $CONTAINER_NAME
  image: $DEV_DOCKER_IMAGE
  environment:
    - AMBARI_SERVER_HOSTNAME=ambari-server
  entrypoint: ["/bin/sh"]
  volumes:
    - "$DEV_AMBARI_PROJECT_DIR/:/ambari"
    - "$HOME/.m2/:/root/.m2"
    - "$DEV_PROJECT_PATH/container/runAgent.sh:/scripts/runAgent.sh"
    - "$HOME/tmp/docker/ambari-agents/ambari-agent-$i:/var/lib/ambari-agent/tmp"
  command: -c '/scripts/runAgent.sh'

EOF
}

gen-kerberos-server-yml(){
  CONTAINER_NAME=kerberos-server
  cat <<EOF >> $1
$CONTAINER_NAME:
  privileged: true
  container_name: $CONTAINER_NAME
  hostname: $CONTAINER_NAME
  volumes:
    - "/dev/urandom:/dev/random"
    - "$HOME/tmp/docker/kdc/log:/var/log/kerberos"
  image: $DEV_KERBEROS_DOCKER_IMAGE
  environment:
    - REALM=$DEV_KERBEROS_REALM
    - DOMAIN_REALM=$DEV_KERBEROS_DOMAIN_REALM

EOF
}


gen-compose-yml(){
  echo "Generating compose file: $1"
  if [ -f  "$1" ]
    then
      backup_yml=$1_$(date +"%Y%m%d_%H%M%S").bak;
      mv $1 $backup_yml
      echo "Backed up previous compose file to: $backup_yml"
  fi
  #gen-database-container-yml $1
  gen-local-db-container-yml $1
  gen-ambari-server-yml $1
  for (( i=1; i<=$DEV_NUMBER_OF_AGENTS; i++ ))
  do
    gen-ambari-agent-yml $1
  done
  gen-kerberos-server-yml $1
  echo "Compose file: $1 ready!"
}

main() {
  generate-dev-env-profile
  set-project-path
  check-dev-env
  check-dev-docker-image
  build-ambari-agent-rpm
  gen-compose-yml docker-compose.yml
}

main "$@"
