#!/usr/bin/env bash -a

# 172.22.105.77	lpuskas-ha-6.novalocal	lpuskas-ha-6	lpuskas-ha-6.novalocal.
# 172.22.105.76	lpuskas-ha-5.novalocal	lpuskas-ha-5	lpuskas-ha-5.novalocal.
# 172.22.105.75	lpuskas-ha-4.novalocal	lpuskas-ha-4	lpuskas-ha-4.novalocal.
# 172.22.105.73	lpuskas-ha-3.novalocal	lpuskas-ha-3	lpuskas-ha-3.novalocal.
# 172.22.105.70	lpuskas-ha-2.novalocal	lpuskas-ha-2	lpuskas-ha-2.novalocal.
# 172.22.105.7	lpuskas-ha-1.novalocal	lpuskas-ha-1	lpuskas-ha-1.novalocal.

hosts='172.22.105.77 172.22.105.76 172.22.105.75 172.22.105.73 172.22.105.70 172.22.105.7'
server='172.22.105.7'


set_yum_repo(){
  cat <<EOF

cd cd /etc/yum.repos.d/

# remove stale repo files
rm -rf ambari.repo
rm -rf ambaribn.repo

yum clean all

# get desired repo from:http://release.eng.hortonworks.com/
wget http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos6/2.x/BUILDS/2.4.0.0-306/ambaribn.repo

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
    "$2"
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
  wget http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos6/2.x/BUILDS/2.4.0.0-306/ambaribn.repo


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
    server)
        h="172.22.108.120"
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

main "$@"
