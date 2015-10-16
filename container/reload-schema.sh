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

echo "Creating the symlink"
ln -s /ambari/ambari-server/src/main/resources/Ambari-DDL-Postgres-CREATE.sql /docker-entrypoint-initdb.d/amabri_schema_create.sql

echo "Proceeding to start"
/bin/bash docker-entrypoint.sh postgres

#main "$@"
