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

setup(){
  : ${DEV_DOCKER_IMAGE:=ambari/docker-dev}

  # yum repo id to mirror
  : ${REPO_ID:="HDP-2.3.2.0"}

  # url that points to source repo file to be mirrored (e.g. http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.3.2.0/hdp.repo)
  : ${REPO_SOURCE_URL:="http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.3.2.0/hdp.repo"}

  # local repository location
  : ${DEV_YUM_REPO_DIR:="$HOME/tmp/docker/repos"}
}

create-yum-repo-mirror() {
  echo "Syncing yum repo $REPO_ID from $REPO_SOURCE_URL to $DEV_YUM_REPO_DIR ..."

  docker run \
      --rm \
      --privileged \
      --entrypoint=/bin/bash \
      -v "$DEV_YUM_REPO_DIR:/tmp" \
      -w /tmp \
      $DEV_DOCKER_IMAGE \
      -c "wget $REPO_SOURCE_URL -O /etc/yum.repos.d/$REPO_ID.repo && reposync -n -p /tmp -r HDP-UTILS-* -r $REPO_ID && ls -d * | xargs -n 1 -I repo_dir createrepo --update repo_dir"
}

gen-yum-repo-yml(){
  DEV_YUM_CONTAINER_NAME=yum-repo

  cat <<EOF > yum-repo.yml
$DEV_YUM_CONTAINER_NAME:
  privileged: true
  container_name: $DEV_YUM_CONTAINER_NAME
  hostname: $DEV_YUM_CONTAINER_NAME
  entrypoint: ["/bin/sh"]
  ports:
    - "80:80"
  volumes:
    - "/dev/urandom:/dev/random"
    - "$DEV_YUM_REPO_DIR:/var/www/html/repos"
  image: $DEV_DOCKER_IMAGE
  command: -c 'httpd -DFOREGROUND'
EOF
}

use-local-repo(){
  B2D_IP=$(boot2docker ip)

  cat <<EOF >$HOME/tmp/local_repo.json
  {
    "Repositories" : {
      "base_url" : "http://$B2D_IP/repos/$REPO_ID",
      "default_base_url" : "http://$B2D_IP/repos/$REPO_ID",
      "latest_base_url" : "http://$B2D_IP/repos/$REPO_ID",
      "mirrors_list" : null,
      "os_type" : "redhat6",
      "repo_id" : "HDP-2.3",
      "repo_name" : "HDP",
      "stack_name" : "HDP",
      "stack_version" : "2.3"
    }
  }

EOF
  curl --verbose -u admin:admin -H "X-Requested-By:ambari" -X PUT -d @"$HOME/tmp/local_repo.json" http://$B2D_IP:8080/api/v1/stacks/HDP/versions/2.3/operating_systems/redhat6/repositories/$REPO_ID
}

main(){
  setup

  if [ "$1" == "put-local-repo" ]
  then
    use-local-repo
  else
    create-yum-repo-mirror
    gen-yum-repo-yml
  fi
}

main "$@"
