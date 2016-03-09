#!/bin/bash -a

# the feature branch the job is operating on
: ${AMBARI_DEV_FEATURE_BRANCH:="trunk"}
AMBARI_DEV_GIT_REPO=https://github.com/sequenceiq/ambari.git
AMBARI_DEV_DOCKER_IMAGE=ambari/docker-dev

# JENKINS_HOME is a builtin var
AMBARI_DEV_PERSISTENT_M2_REPO=$JENKINS_HOME/maven-repo
AMBARI_DEV_PERSISTENT_NODE_REPO=$JENKINS_HOME/node-repo
AMBARI_DEV_JENKINS_TMP_DIR=$WORKSPACE/tmp

# maven commands
AMBARI_DEV_MVN_RPM_COMMAND='mvn clean package rpm:rpm -Dstack.distribution=HDP -Dmaven.clover.skip=true -Dfindbugs.skip=true -DskipTests -Dpython.ver="python>=2.6"'
AMBARI_DEV_MVN_INSTALL_COMMAND='mvn clean install -U -DskipTests -DskipPythonTests -Dmaven.clover.skip=true -Dfindbugs.skip=true'
AMBARI_DEV_MVN_TEST_COMMAND="mvn test -projects ambari-server"


docker-build-dev-image(){
  if [[ "$(docker images -q $AMBARI_DEV_DOCKER_IMAGE 2> /dev/null)" == "" ]]; then
    echo "Building the dev image: $AMBARI_DEV_DOCKER_IMAGE"
    docker build -t $AMBARI_DEV_DOCKER_IMAGE .
  fi
}

git-checkout(){
  # delete temporary folder if exists
  if [ -d "$AMBARI_DEV_JENKINS_TMP_DIR" ]; then
    sudo rm -rf $AMBARI_DEV_JENKINS_TMP_DIR/ambari
  fi

  # create the temporary working directory
  mkdir $AMBARI_DEV_JENKINS_TMP_DIR
  cd $AMBARI_DEV_JENKINS_TMP_DIR

  git clone $AMBARI_DEV_GIT_REPO;
  cd ambari
  git checkout $AMBARI_DEV_FEATURE_BRANCH;
}


execute-jenkins-job(){
  AMBARI_DEV_MODULE=$1
  MVN_CMD="${@:2}"
  echo "Executing build task [ $MVN_CMD ] on module [ $AMBARI_DEV_MODULE ]"

  docker run \
    --rm --privileged \
    --net="host" \
    -v $AMBARI_DEV_JENKINS_TMP_DIR/ambari/:/ambari \
    -v $AMBARI_DEV_PERSISTENT_M2_REPO:/root/.m2 \
    -v $AMBARI_DEV_PERSISTENT_NODE_REPO:/root/.npm \
    --entrypoint=/bin/bash \
    -w /ambari/ \
    "$AMBARI_DEV_DOCKER_IMAGE" \
    -c "$MVN_CMD"
}

install-all(){
  # execute-jenkins-job ambari-metrics $AMBARI_DEV_MVN_INSTALL_COMMAND
  # execute-jenkins-job ambari-views $AMBARI_DEV_MVN_INSTALL_COMMAND
  # execute-jenkins-job ambari-web $AMBARI_DEV_MVN_INSTALL_COMMAND
  # execute-jenkins-job ambari-server $AMBARI_DEV_MVN_INSTALL_COMMAND
  # execute-jenkins-job ambari-agent $AMBARI_DEV_MVN_INSTALL_COMMAND

  execute-jenkins-job "" $AMBARI_DEV_MVN_INSTALL_COMMAND
}

rpm-all(){
  execute-jenkins-job ambari-metrics $AMBARI_DEV_MVN_RPM_COMMAND
  execute-jenkins-job ambari-server $AMBARI_DEV_MVN_RPM_COMMAND
  execute-jenkins-job ambari-agent $AMBARI_DEV_MVN_RPM_COMMAND
}

main (){

  docker-build-dev-image
  git-checkout

  case $1 in
    install-all )
      install-all
      ;;
    test-server )
      execute-jenkins-job ambari-server $AMBARI_DEV_MVN_TEST_COMMAND
      ;;
    rpm-all )
      rpm-all
      ;;
    *)
  esac
}

main "$@"
