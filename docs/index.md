### Ambari development environment
Docker based development environment for Ambari

This project aims to ease the development of the ambari server by setting up a real-like
development environment using docker containers.

### Prerequisites
The following software components need to be installed:
* [Boot2docker] (http://boot2docker.io/)
* [docker-compose] (https://docs.docker.com/compose/install/)

### The concept
- the source code is cloned to the host machine
- the project is made available to the containers as docker volumes
- development is done in the preferred IDE, on the host
- components (the server and the agents) run in docker containers

###  Usage

1. clone the project from the git repo:
```git clone git@github.com:lpuskas/ambari-dev-env.git```

2. set up your development profile:
```./setup.sh``` and set the variables in the generated `.dev-profile` file

3. run the ```./setup.sh``` again

4. run the ```./startDevEnv.sh```

5. you remotely debug the code from your IDE
