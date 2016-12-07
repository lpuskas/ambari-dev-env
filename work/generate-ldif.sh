#!/bin/bash
: ${DEV_LDAP_USER_PREFIX:="jocika"}
: ${DEV_LDAP_USER_CNT:="10"}

generate-ldif(){
  suffix=$1

  cat <<EOF >> test-users.ldif
dn: uid=$DEV_LDAP_USER_PREFIX$suffix,ou=people,ou=hdp,dc=dev,dc=local
objectClass: inetOrgPerson
objectClass: organizationalPerson
objectClass: person
objectClass: top
cn: $DEV_LDAP_USER_PREFIX$suffix
sn: $DEV_LDAP_USER_PREFIX$suffix
uid: $DEV_LDAP_USER_PREFIX$suffix


EOF
}

generate-ldifs(){
  echo "Generating $DEV_LDAP_USER_CNT test ldap usters "
  for (( i=1; i<=$DEV_LDAP_USER_CNT; i++ ))
  do
    generate-ldif $i
  done
}

main(){
  if [ ! -z $1 ]; then
    DEV_LDAP_USER_CNT=$1
  fi

  generate-ldifs $DEV_LDAP_USER_CNT
}

main "$@"
