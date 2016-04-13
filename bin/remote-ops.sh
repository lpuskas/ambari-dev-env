#!/usr/bin/env bash -a

# 172.22.109.117	lpuskas-ha-6.novalocal	lpuskas-ha-6	lpuskas-ha-6.novalocal.
# 172.22.109.1	lpuskas-ha-5.novalocal	lpuskas-ha-5	lpuskas-ha-5.novalocal.
# 172.22.109.0	lpuskas-ha-4.novalocal	lpuskas-ha-4	lpuskas-ha-4.novalocal.
# 172.22.108.122	lpuskas-ha-3.novalocal	lpuskas-ha-3	lpuskas-ha-3.novalocal.
# 172.22.108.121	lpuskas-ha-2.novalocal	lpuskas-ha-2	lpuskas-ha-2.novalocal.
# 172.22.108.120	lpuskas-ha-1.novalocal	lpuskas-ha-1	lpuskas-ha-1.novalocal.


hosts='172.22.109.117 172.22.109.1 172.22.109.0 172.22.108.122 172.22.108.121 172.22.108.120'
server='172.22.108.120'


reset_agent(){
  ssh -i ~/.ssh/hw-dev-keypair.pem root@"$1" <<EOF

  # cd /etc/yum.repos.d/
  # rm -rf ambari.repo
  # rm -rf ambaribn.repo
  # wget  http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos6/2.x/BUILDS/2.2.2.0-408/ambaribn.repo

  ambari-agent stop

  # kills all python processes
  pkill python

  # kills all java processes
  pkill java

  # Remove mysql data
  rm -rf /var/lib/mysql/

  # housekeeping
  # yum remove -y ambari-agent
  rm -rf /hadoop
  rm -rf /var/log/ambari-2*

  yum install -y ambari-agent
  ambari-agent reset lpuskas-ha-1.novalocal
  ambari-agent start
EOF
}

reset_server(){
  ssh -i ~/.ssh/hw-dev-keypair.pem root@"$1" <<EOF
  ambari-server stop
  rm -rf /hadoop
  # "yum remove -y ambari-server && "\

  # yum install -y ambari-server

  # ambari-server setup -s
  ambari-server reset -s
  ambari-server start
EOF
}

main(){
  case $1 in
    server)
        h="172.22.89.54"
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
    *)
       echo "fax"
       ;;
  esac
}

main "$@"
