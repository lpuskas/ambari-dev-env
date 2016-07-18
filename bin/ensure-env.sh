#!/usr/bin/env bash -a
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

source .dev-profile

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


show_dev_env(){
  echo "Development environement variables: "
  for i in ${!DEV_*}
  do
    eval val=\$$i
    echo $i = $val
  done
}



main(){
  show_dev_env
}

main "$@"
