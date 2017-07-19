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

if [ -z "$1" ]; then
  echo 'HDP repo URL is required...exiting'
    exit 1
fi

if [ -z "$2" ]; then
  echo 'Docker image tag is required...exiting'
    exit 1
fi

HDP_REPO_URL="$1"
TAG="$2"


HDP_REPO_FILE=$(dirname "$0")/../hdp.repo
cat >> $HDP_REPO_FILE<<EOF
[$TAG]
name=$TAG
baseurl=$HDP_REPO_URL
gpgcheck=0
enabled=1
priority=1

[HDP-UTILS]
name=HDP-UTILS-1.1.0.21
baseurl=http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.21/repos/centos6
enabled=1
gpgcheck=0

EOF



echo "Building docker image with HPD packages installed from $HDP_REPO_URL"
echo
echo "Building ambari/docker-dev:$TAG"

docker build --rm=true -f $(dirname "$0")/../hdp_preinstall.dockerfile -t "ambari/docker-dev:$TAG" .

rm $HDP_REPO_FILE
