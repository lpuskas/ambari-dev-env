#!/usr/bin/env bash -a


# *************** /etc/hosts info ****************
# 172.22.91.166	lpuskas-7.openstacklocal	lpuskas-7	lpuskas-7.openstacklocal.
# 172.22.91.165	lpuskas-6.openstacklocal	lpuskas-6	lpuskas-6.openstacklocal.
# 172.22.91.164	lpuskas-5.openstacklocal	lpuskas-5	lpuskas-5.openstacklocal.
# 172.22.91.163	lpuskas-4.openstacklocal	lpuskas-4	lpuskas-4.openstacklocal.
# 172.22.91.161	lpuskas-3.openstacklocal	lpuskas-3	lpuskas-3.openstacklocal.
# 172.22.91.160	lpuskas-2.openstacklocal	lpuskas-2	lpuskas-2.openstacklocal.
# 172.22.91.159	lpuskas-1.openstacklocal	lpuskas-1	lpuskas-1.openstacklocal.
# ************************************************
hosts='172.22.91.160 172.22.91.161 172.22.91.163 172.22.91.164 172.22.91.165 172.22.91.166'
server='172.22.91.159'


set_yum_repo(){
  cat <<EOF

cd /etc/yum.repos.d/

# remove stale repo files
rm -rf ambari.repo
rm -rf ambaribn.repo

yum clean all

curl -o ambari.repo http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos6/2.x/BUILDS/2.2.1.12-11/ambaribn.repo

EOF
}

start_server(){
  cat <<EOF
  ambari-server setup -s
  ambari-server start
EOF
}

start_agent(){
  cat <<EOF
  ambari-agent reset $server
  ambari-agent start
EOF
}

install_ambari_cmd(){
  cat <<EOF
yum install -y ambari-server

yum install -y ambari-agent
EOF

}

uninstall_ambari_cmd(){
  cat <<EOF
yum remove -y ambari-server

yum remove -y ambari-agent
EOF

}

cleanup_files_cmd(){
  cat <<EOF
    rm -rf /hadoop
    rm -rf /var/log/ambari-2*

    # Remove mysql data
    rm -rf /var/lib/mysql/
EOF

}

cleanup_processes_cmd(){
  cat <<EOF
  # kills all python processes
  pkill python

  # kills all java processes
  pkill java
EOF
}


execute_cmd(){
  ssh -i ~/.ssh/hw-dev-keypair.pem root@"$1"  <<EOF
    $2
EOF
}


reset_agent(){
  ssh -i ~/.ssh/hw-dev-keypair.pem root@"$1" <<EOF

  # stop the agent if running
  ambari-agent stop

  cd /etc/yum.repos.d/
  rm -rf ambari.repo
  rm -rf ambaribn.repo

  yum clean all

  # get desired repo from:http://release.eng.hortonworks.com/
  wget http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos6/2.x/BUILDS/2.2.1.12-11/ambaribn.repo


  # kills all python processes
  pkill python

  # kills all java processes
  pkill java

  # Remove mysql data
  rm -rf /var/lib/mysql/

  # housekeeping
  yum remove -y ambari-agent
  rm -rf /hadoop
  rm -rf /var/log/ambari-*

  yum install -y ambari-agent
  ambari-agent reset lpuskas-ha-1.novalocal
  ambari-agent start
EOF
}

reset_server(){
  ssh -i ~/.ssh/hw-dev-keypair.pem root@"$1" <<EOF
  ambari-server stop
  rm -rf /hadoop
  yum remove -y ambari-server
  yum install -y ambari-server

  ambari-server setup -s
//  ambari-server reset -s
  ambari-server start
EOF
}

main(){
  case $1 in
    yum-repos)
       execute_cmd $server "$(set_yum_repo)"
       for h in $hosts;
       do
         execute_cmd $h "$(set_yum_repo)"
       done;
    ;;
    install)
       execute_cmd $server "yum install -y ambari-server"
       for h in $hosts;
       do
         execute_cmd $h "yum install -y ambari-agent"
       done;
    ;;
    start)
      #  execute_cmd $server "$(start_server)"
       for h in $hosts;
       do
         execute_cmd $h "$(start_agent)"
       done;
    ;;

    yum-repos)
       execute_cmd $server "$(set_yum_repo)"
       for h in $hosts;
       do
         execute_cmd $h "$(set_yum_repo)"
       done;
    ;;
    server)
        echo "************* Processing server, host: [ $server ] ****************"
        reset_server $server
       ;;
    agent)
        for h in $hosts;
        do
            echo "************* Processing agents, host: [ $h ] ****************"
            reset_agent "$h"
        done;
       ;;
    uninstall-ambari)
        for h in $hosts;
        do
          execute_cmd $h "$(uninstall_ambari_cmd)"
        done;
       ;;
    *)
       ;;
  esac
}

# install yum repo
# distribute private ssh keys

main "$@"
