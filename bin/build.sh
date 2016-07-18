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


build_modules(){
  modules_to_build=(ambari-metrics ambari-admin ambari-views)
  echo "Building modules: ${modules_to_build[*]}"
  # DEV_AMBARI_PROJECT_DIR=~/prj/ambari
  for module in ${modules_to_build[*]}; do
    echo "Building module: $module"
    pushd "$DEV_AMBARI_PROJECT_DIR/$module"
    echo "Switched to folder: $(pwd)"
    mvn package -DskipTests -Drat.skip=true
    popd
    echo "Switched back to: $(pwd)"
  done
}


main() {
  echo "Dir: $(pwd)"
  source bin/ensure-env.sh
  build_modules
}

main "$@"
