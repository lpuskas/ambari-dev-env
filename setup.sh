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
: ${DEV_KERBEROS_REALM:=DEV.LOCAL}
: ${DEV_KERBEROS_DOMAIN_REALM:=node.dc1.consul}
: ${DEV_AMBARI_PASSPHRASE:=DEV}
: ${DEV_AMBARI_SECURITY_MASTER_KEY:=@mb@r1-m@st3r-k3y}
: ${DEV_YUM_REPO_DIR:="$HOME/tmp/docker/repos"}
: ${LDAP_BASE_DOMAIN:=dev.local}
: ${LDAP_ROOTPASS:=s3cr3tpassw0rd}
: ${DEV_DATABASE_SERVER_CONTAINER_MEM_LIMIT:=128m}
: ${DEV_KERBEROS_SERVER_CONTAINER_MEM_LIMIT:=64m}
: ${DEV_AMBARI_SERVER_CONTAINER_MEM_LIMIT:=1g}
: ${DEV_AMBARI_AGENT_CONTAINER_MEM_LIMIT:=2g}
: ${DEV_ENABLE_CONTAINER_MONITORING:="false"}
: ${DEV_DOCKER_AGENT_IMAGE_TAG:=latest}
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

# Custom pass phrase to be used for signing agent certificates by Ambari in case of 2-way ssl communication
DEV_AMBARI_PASSPHRASE=DEV

# Custom Ambari server master key
#DEV_AMBARI_SECURITY_MASTER_KEY=

# The base domain in LDAP (this is the domain for the LDAP admin user cn=admin )
# LDAP_BASE_DOMAIN=

# Password for LDAP admin user
# LDAP_ROOTPASS=


# Hard memory limit for the database serever container
# DEV_DATABASE_SERVER_CONTAINER_MEM_LIMIT=

# Hard memory limit for kerberos serevr container
# DEV_KERBEROS_SERVER_CONTAINER_MEM_LIMIT=

# Hard memory limit for ambari server container
# DEV_AMBARI_SERVER_CONTAINER_MEM_LIMIT=

# Hard limit for ambari agent container
# DEV_AMBARI_AGENT_CONTAINER_MEM_LIMIT=

# Enable/disable container monitoring
# DEV_ENABLE_CONTAINER_MONITORING="false"

# The docker image tag that identifies the
# image to use to spawn ambari agents.
# This allows to use images that have HDP packages pre-installed.
# e.g DEV_DOCKER_AGENT_IMAGE_TAG=HDP-2.5.3.0, could be
# an image that has HDP-2.5.3.0 packaged pre-installed
DEV_DOCKER_AGENT_IMAGE_TAG=latest


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

build-rpm(){
  if [ -z $1 ]
  then
    echo "No ambari module name provided!"
    exit 1;
  fi

  DEV_MODULE=$1
  DEV_MVN_RPM_COMMAND=""
  DEV_RPM_EXISTS_COMMAND=""
  container_workspace="/ambari"

  case "$DEV_MODULE" in
    ambari-metrics)
        DEV_RPM_EXISTS_CHECK_DIR="$DEV_AMBARI_PROJECT_DIR/$DEV_MODULE/ambari-metrics-assembly/target/rpm"
        DEV_MVN_RPM_COMMAND="mvn package -Dbuild-rpm -Dstack.distribution=HDP -DskipTests -Dmaven.clover.skip=true -Dfindbugs.skip=true -Drat.skip=true -Dpython.ver='python >= 2.6'"
    ;;
    *)
        DEV_RPM_EXISTS_CHECK_DIR="$DEV_AMBARI_PROJECT_DIR/$DEV_MODULE/target/rpm/$DEV_MODULE/RPMS/x86_64"

        DEV_MVN_RPM_COMMAND="mvn package -am rpm:rpm -B -Dstack.distribution=HDP -DskipTests -Dmaven.clover.skip=true -Dfindbugs.skip=true -Drat.skip=true -Dpython.ver=\"python >= 2.6\" -pl $DEV_MODULE"
  esac

  echo -n "Build rpm for $DEV_MODULE ... "

  if [ -d "$DEV_RPM_EXISTS_CHECK_DIR" ]
  then
    echo "Skipping due to [ -d $DEV_RPM_EXISTS_CHECK_DIR ] command returned true !"
  else
    echo "Running command: [ $DEV_MVN_RPM_COMMAND ]"
    docker run \
      --rm \
      --privileged \
      --entrypoint=/bin/bash \
      -v $DEV_AMBARI_PROJECT_DIR/:/ambari \
      -v $HOME/.m2/:/root/.m2 \
      -w $container_workspace \
      $DEV_DOCKER_IMAGE \
      -c "$DEV_MVN_RPM_COMMAND"
  fi

}

gen-local-db-container-yml(){
  CONTAINER_NAME=ambari-db
  cat >> $1<<EOF
$CONTAINER_NAME:
  privileged: true
  container_name: $CONTAINER_NAME
  hostname: $CONTAINER_NAME
  mem_limit: $DEV_DATABASE_SERVER_CONTAINER_MEM_LIMIT
  memswap_limit: $DEV_DATABASE_SERVER_CONTAINER_MEM_LIMIT
  ports:
    - "5432:5432"
  environment:
    - POSTGRES_USER=ambari
    - POSTGRES_PASSWORD=bigdata
  volumes:
    - "$DEV_AMBARI_PROJECT_DIR/:/ambari"
    - "$DEV_PROJECT_PATH/container:/scripts"
  entrypoint: /scripts/reload-schema.sh
  image: postgres:9.4

EOF
}

gen-ambari-server-yml(){
  CONTAINER_NAME=ambari-server
  cat >> $1<<EOF
$CONTAINER_NAME:
  privileged: true
  container_name: $CONTAINER_NAME
  hostname: $CONTAINER_NAME.node.dc1.consul
  mem_limit: $DEV_AMBARI_SERVER_CONTAINER_MEM_LIMIT
  memswap_limit: $DEV_AMBARI_SERVER_CONTAINER_MEM_LIMIT
  ports:
    - "$DEV_AMBARI_SERVER_DEBUG_PORT:50100"
    - "8080:8080"
  environment:
    - SERVER_VERSION=$DEV_AMBARI_SERVER_VERSION
    - AMBARI_PASSPHRASE=$DEV_AMBARI_PASSPHRASE
    - PYTHONPATH=/ambari/ambari-common/src/main/python:/ambari/ambari-server/src/main/python
    - AMBARI_CONF_DIR=/ambari-server-conf
    - AMBARI_SECURITY_MASTER_KEY=$DEV_AMBARI_SECURITY_MASTER_KEY
    - ROOT=/
    - TERM=screen
  volumes:
    - "$DEV_AMBARI_PROJECT_DIR/:/ambari"
    - "$HOME/.m2/:/root/.m2"
    - "$DEV_PROJECT_PATH/container:/scripts"
    - "$DEV_AMBARI_SERVER_CONFIG_DIR/:/ambari-server-conf"
    - "$DEV_AMBARI_SERVER_CONFIG_DIR/:/etc/ambari-server/conf"
    - "$DEV_AMBARI_SERVER_CONFIG_DIR/krb5.conf:/etc/krb5.conf"
    - "$HOME/tmp/docker/ambari-server/tmp:/tmp/ambari-server"
    - "$HOME/tmp/docker/ambari-server/logs:/var/log/ambari-server"
    - "$HOME/tmp/docker/ambari-server/keytabs:/keytabs/ambari-server"
    - "$HOME/tmp/docker/ambari-server/keytabs:/etc/security/keytabs"
    - "$HOME/tmp/docker/ambari-server/ssl-keys:/ssl-keys/ambari-server"
    - "$DEV_AMBARI_SERVER_CONFIG_DIR/consul.json:/etc/consul.json"
    - "$HOME/tmp/docker/ambari-server/views:/views"
  dns:
    - 0.0.0.0
  links:
    - ambari-db
    - kerberos-server
  image: $DEV_DOCKER_IMAGE
  entrypoint: ["/bin/sh"]
  command: -c '/scripts/runServer.sh $DEV_AMBARI_REPO_URL'

EOF
}

gen-ambari-agent-yml(){
  CONTAINER_NAME=ambari-agent-$i
  cat <<EOF >> $1
$CONTAINER_NAME:
  privileged: true
  container_name: $CONTAINER_NAME
  hostname: $CONTAINER_NAME.node.dc1.consul
  mem_limit: $DEV_AMBARI_AGENT_CONTAINER_MEM_LIMIT
  memswap_limit: $DEV_AMBARI_AGENT_CONTAINER_MEM_LIMIT
  image: "$DEV_DOCKER_IMAGE:$DEV_DOCKER_AGENT_IMAGE_TAG"
  dns:
    - 0.0.0.0
  links:
    - ambari-server
    - kerberos-server
  environment:
    - AMBARI_SERVER_HOSTNAME=ambari-server.node.dc1.consul
    - TERM=screen
  entrypoint: ["/bin/sh"]
  volumes:
    - "$DEV_AMBARI_PROJECT_DIR/:/ambari"
    - "$DEV_PROJECT_PATH/container/runAgent.sh:/scripts/runAgent.sh"
    - "$HOME/tmp/docker/ambari-agents/ambari-agent-$i/log:/var/log/ambari-agent"
    - "$DEV_AMBARI_SERVER_CONFIG_DIR/consul.json:/etc/consul.json"
    - "$DEV_AMBARI_SERVER_CONFIG_DIR/agent_container_resources.json:/etc/resource_overrides/agent_resources.json"
  command: -c '/scripts/runAgent.sh $DEV_AMBARI_REPO_URL'

EOF
}

gen-kerberos-server-yml(){
  CONTAINER_NAME=kerberos-server
  cat <<EOF >> $1
$CONTAINER_NAME:
  privileged: true
  container_name: $CONTAINER_NAME
  hostname: $CONTAINER_NAME
  mem_limit: $DEV_KERBEROS_SERVER_CONTAINER_MEM_LIMIT
  memswap_limit: $DEV_KERBEROS_SERVER_CONTAINER_MEM_LIMIT
  volumes:
    - "/dev/urandom:/dev/random"
    - "$HOME/tmp/docker/kdc/log:/var/log/kerberos"
  image: $DEV_KERBEROS_DOCKER_IMAGE
  environment:
    - REALM=$DEV_KERBEROS_REALM
    - DOMAIN_REALM=$DEV_KERBEROS_DOMAIN_REALM

EOF
}

gen-docker-container-monitoring-yml(){
  cat <<EOF >> $1
influxsrv:
  image: "tutum/influxdb:0.9"
  container_name: "influxsrv"
  ports:
    - "8083:8083"
    - "8086:8086"
  expose:
    - "8090"
    - "8099"
  environment:
    - PRE_CREATE_DB=cadvisor
    - ADMIN_USER=root
    - INFLUXDB_INIT_PWD=root
cadvisor:
  image: "google/cadvisor:v0.24.1"
  container_name: "cadvisor"
  privileged: true
  volumes:
    - "/:/rootfs:ro"
    - "/var/run:/var/run:rw"
    - "/sys:/sys:ro"
    - "/var/lib/docker/:/var/lib/docker:ro"
  links:
    - "influxsrv:influxsrv"
  ports:
    - "8088:8080"
  command: "-storage_driver=influxdb -storage_driver_db=cadvisor -storage_driver_host=influxsrv:8086"
grafana:
  image: "grafana/grafana:3.1.1"
  container_name: "grafana"
  ports:
    - "3000:3000"
  environment:
    - INFLUXDB_HOST=influxsrv
    - INFLUXDB_PORT=8086
    - INFLUXDB_NAME=cadvisor
    - INFLUXDB_USER=root
    - INFLUXDB_PASS=root
  links:
    - "influxsrv:influxsrv"
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

  if [ "$DEV_ENABLE_CONTAINER_MONITORING" = "true" ]; then
        gen-docker-container-monitoring-yml $1
  fi

  echo "Compose file: $1 ready!"
}

main() {
  set-project-path
  generate-dev-env-profile
  check-dev-env
  check-dev-docker-image

  build-rpm "ambari-metrics"
  build-rpm "ambari-agent"

  if [ "$1" = "build-server-rpm" ]
    then
      build-rpm "ambari-server"
  fi

  gen-compose-yml docker-compose.yml

}

main "$@"
