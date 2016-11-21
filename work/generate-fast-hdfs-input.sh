#!/bin/bash
: ${DEV_LDAP_USER_PREFIX:="nono"}
: ${DEV_LDAP_USER_CNT:="10"}

generate-json-entry(){
  suffix=$1

  cat <<EOF >> fast-hdfs-test.json
{
  "target": "/user/$DEV_LDAP_USER_PREFIX$suffix",
  "action": "create",
  "manageIfExists": true,
  "mode": "755",
  "owner": "$DEV_LDAP_USER_PREFIX$suffix",
  "type": "directory"
},
EOF
}

generate-json-entries(){
  echo "Generating $DEV_LDAP_USER_CNT test json entries "
  cat <<EOF >> fast-hdfs-test.json
  [
EOF
  for (( i=1; i<=$DEV_LDAP_USER_CNT; i++ ))
  do
    generate-json-entry $i
  done
  cat <<EOF >> fast-hdfs-test.json
  {
    "target": "/last",
    "action": "create",
    "manageIfExists": true,
    "mode": "755",
    "owner": "last",
    "type": "directory"
  }
  ]
EOF

}

main(){
  if [ ! -z $1 ]; then
    DEV_LDAP_USER_CNT=$1
  fi

  generate-json-entries $DEV_LDAP_USER_CNT
}

main "$@"
