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

# Custom pass phrase to be used for signing agent certificates by Ambari in case of 2-way ssl communicarion
DEV_AMBARI_PASSPHRASE=DEV

# Custom Ambari server master key
#DEV_AMBARI_SECURITY_MASTER_KEY=


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
      -c 'mvn package rpm:rpm -Dstack.distribution=HDP -Dmaven.clover.skip=true -Dfindbugs.skip=true -DskipTests -Dpython.ver="python >= 2.6"'
  fi
}

build-ambari-server-rpm() {
  if [ "$(ls $DEV_AMBARI_PROJECT_DIR/ambari-server/target/rpm/ambari-server/RPMS/x86_64 | wc -l)" -ge "1" ]
  then
    echo "Ambari server rpm found."
  else
    echo "Building Ambari Server rpm ..."
    docker run \
      --rm --privileged \
      -v $DEV_AMBARI_PROJECT_DIR/:/ambari \
      -v $HOME/.m2/:/root/.m2 --entrypoint=/bin/bash \
      -w /ambari/ambari-server \
      $DEV_DOCKER_IMAGE \
      -c 'mvn clean package rpm:rpm -Dstack.distribution=HDP -Dmaven.clover.skip=true -Dfindbugs.skip=true -DskipTests -Dpython.ver="python >= 2.6"'
  fi
}

build-ambari-metrics-rpm() {
  if [ "$(ls $DEV_AMBARI_PROJECT_DIR/ambari-metrics/ambari-metrics-assembly/target/rpm  | wc -l)" -ge "1" ]
  then
    echo "Ambari metrics rmp found."
  else
    echo "Building Ambari Metrics rpm ..."
    docker run \
      --rm --privileged \
      -v $DEV_AMBARI_PROJECT_DIR/:/ambari \
      -v $HOME/.m2/:/root/.m2 --entrypoint=/bin/bash \
      -w /ambari/ambari-metrics \
      $DEV_DOCKER_IMAGE \
      -c 'mvn package -Dbuild-rpm -DskipTests -Dmaven.clover.skip=true -Dfindbugs.skip=true -DskipTests -Dpython.ver="python >= 2.6"'
  fi
}

create-yum-repo-mirror() {
  # yum repo id to mirror
  repoid=$1

  # url thr points to source repo file to be mirrored (e.g. http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.3.2.0/hdp.repo)
  repo_source_url=$2

  repos_dir="$HOME/tmp/docker/repos"

  echo "Syncing yum repo $repoid from $repo_source_url to $repos_dir ..."

  docker run \
      --rm --privileged \
      -v "$repos_dir:/tmp" --entrypoint=/bin/bash \
      -w /tmp \
      $DEV_DOCKER_IMAGE \
      -c "wget $repo_source_url -O /etc/yum.repos.d/$repoid.repo && reposync -n -p /tmp -r HDP-UTILS-* -r $repoid && ls -d * | xargs -n 1 -I repo_dir createrepo --update repo_dir"

  # done with syncing the repo, now start a conatiner with httpd pointing to repos directory
  CONTAINER_NAME=yum-repos

  docker run \
      -d \
      -v "$repos_dir:/var/www/html/repos" --entrypoint=/bin/bash \
      --name "$CONTAINER_NAME" --hostname "$CONTAINER_NAME" \
      -p 80:80 \
      $DEV_DOCKER_IMAGE \
      -c 'httpd -DFOREGROUND'
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
  ports:
    - "$DEV_AMBARI_SERVER_DEBUG_PORT:50100"
    - "8080:8080"
  environment:
    - SERVER_VERSION=$DEV_AMBARI_SERVER_VERSION
    - AMBARI_PASSPHRASE=$DEV_AMBARI_PASSPHRASE
    - PYTHONPATH=/ambari/ambari-common/src/main/python:/ambari/ambari-server/src/main/python
    - AMBARI_CONF_DIR=/ambari-server-conf
    - AMBARI_SECURITY_MASTER_KEY=$DEV_AMBARI_SECURITY_MASTER_KEY
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
    - "$DEV_AMBARI_SERVER_CONFIG_DIR/consul.json:/etc/consul.json"
  dns: 0.0.0.0
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
  image: $DEV_DOCKER_IMAGE
  dns: 0.0.0.0
  links:
    - ambari-server
    - kerberos-server
  environment:
    - AMBARI_SERVER_HOSTNAME=ambari-server.node.dc1.consul
  entrypoint: ["/bin/sh"]
  volumes:
    - "$DEV_AMBARI_PROJECT_DIR/:/ambari"
    - "$HOME/.m2/:/root/.m2"
    - "$DEV_PROJECT_PATH/container/runAgent.sh:/scripts/runAgent.sh"
    - "$HOME/tmp/docker/ambari-agents/ambari-agent-$i/log:/var/log/ambari-agent"
    - "$DEV_AMBARI_SERVER_CONFIG_DIR/consul.json:/etc/consul.json"
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
  build-ambari-metrics-rpm
  build-ambari-agent-rpm
  if [ "$1" = "build-server-rpm" ]
    then
      build-ambari-server-rpm
  fi
  gen-compose-yml docker-compose.yml
}

set-project-path
generate-dev-env-profile
check-dev-env
check-dev-docker-image


case "$1" in
  repo-mirror)
     repoid=$2
     repo_source_url=$3
     echo "Setting up Yum repo mirror for repoid=$repoid"

     create-yum-repo-mirror "$repoid" "$repo_source_url"
     ;;

  *)
    main "$@"
esac
