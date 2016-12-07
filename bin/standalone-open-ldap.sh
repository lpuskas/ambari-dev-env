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


setup() {
  : ${DEV_OPENLDAP_IMAGE:="nickstenning/slapd"}
  : ${LDAP_BASE_DOMAIN:="dev.local"}
  : ${LDAP_SEARCH_BASE:="dc=dev,dc=local"}
  : ${LDAP_ROOTPASS:="s3cr3tpassw0rd"}
  : ${LDAP_ADMIN_USER:="cn=admin,dc=dev,dc=local"}
}

gen-openldap-yml() {
  DEV_OPENLDAP_CONTAINER_NAME=openldap

  cat <<EOF > openldap.yml
$DEV_OPENLDAP_CONTAINER_NAME:
  privileged: true
  container_name: $DEV_OPENLDAP_CONTAINER_NAME
  hostname: $DEV_OPENLDAP_CONTAINER_NAME
  ports:
    - "389:389"
  environment:
    - LDAP_DOMAIN=$LDAP_BASE_DOMAIN
    - LDAP_ORGANISATION=Hortonworks
    - LDAP_ROOTPASS=$LDAP_ROOTPASS
  image: $DEV_OPENLDAP_IMAGE
EOF

}

ldap_exists() {
  entry_to_search=$1

  found_entry=$(ldapsearch -x -h "$B2D_IP" -LLL -D "$LDAP_ADMIN_USER" -w "$LDAP_ROOTPASS"  -b "$LDAP_SEARCH_BASE" -u "$entry_to_search" | grep ufn:)

  if [ -n "$found_entry" ]
  then
    return 0
  else
    return 1
  fi


}

openldap_init() {
  #B2D_IP=$(docker-machine ip test)
  B2D_IP=localhost
  echo "Initializing OpenLDAP ..."
  # verify that openldap is up and running by searching for the admin user
  ldapsearch -x -h "$B2D_IP" -D "$LDAP_ADMIN_USER" -w "$LDAP_ROOTPASS" -b "$LDAP_SEARCH_BASE"  "cn=admin" > /dev/null

  if [ $? -eq 0 ]
  then
    if  ! (ldap_exists "ou=hdp" && ldap_exists "ou=people" && ldap_exists "ou=groups") ; then
      # Load initial data skeleton for HDP organizational unit, groups and people
      ldapadd -x -h "$B2D_IP" -D "$LDAP_ADMIN_USER" -w "$LDAP_ROOTPASS" -f conf/ldap-init.ldif

      if [ $? -ne 0 ]; then
        echo "Initializing OpenLDAP failed! Check if OpenLDAP container is up and running!" 1>&2
        exit 1
      fi

      # Perform sanity check on initial data
      if !  ldap_exists "ou=hdp" || ! ldap_exists "ou=people" || ! ldap_exists "ou=groups"; then
        echo "OpenLDAP data initialisation failed!" 1>&2
        exit 1
      fi
    fi

  else
    echo "Verify admin user in OpenLDAP failed! Check if OpenLDAP container is up and running!" 1>&2
    exit 1
  fi

  echo "Completed"

}

main() {
  setup
  gen-openldap-yml
  docker-compose -f openldap.yml up -d

  # Wait a few secs to give time openldap container to be up
  # and fully operational
  sleep 3s

  openldap_init
}

main "$@"
