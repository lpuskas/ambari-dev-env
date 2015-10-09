#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

FROM centos:centos6

RUN echo root:changeme | chpasswd

RUN yum clean all -y && yum update -y

## Install some basic utilities that aren't in the default image
RUN yum clean all -y && yum update -y
RUN yum -y install vim wget rpm-build sudo which telnet tar openssh-server openssh-clients ntp git python-devel python-setuptools httpd krb5-libs krb5-workstation

# phantomjs dependency
RUN yum -y install fontconfig freetype libfreetype.so.6 libfontconfig.so.1 libstdc++.so.6
RUN rpm -e --nodeps --justdb glibc-common
RUN yum -y install glibc-common

ENV HOME /root

#Install JAVA
RUN wget --no-check-certificate --no-cookies --header "Cookie:oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u55-b13/jdk-7u55-linux-x64.rpm -O jdk-7u55-linux-x64.rpm
RUN yum -y install jdk-7u55-linux-x64.rpm
ENV JAVA_HOME /usr/java/default/

#Install Maven
RUN mkdir -p /opt/maven
WORKDIR /opt/maven
RUN wget http://apache.cs.utah.edu/maven/maven-3/3.0.5/binaries/apache-maven-3.0.5-bin.tar.gz
RUN tar -xvzf /opt/maven/apache-maven-3.0.5-bin.tar.gz
RUN rm -rf /opt/maven/apache-maven-3.0.5-bin.tar.gz

ENV M2_HOME /opt/maven/apache-maven-3.0.5
ENV MAVEN_OPTS -Xmx2048m -XX:MaxPermSize=256m
ENV PATH $PATH:$JAVA_HOME/bin:$M2_HOME/bin
ENV AMBARI_VERSION=2.1.0.0

# SSH key
RUN ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''
RUN cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys
RUN sed -ri 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config

# Install python, nodejs and npm
RUN yum -y install http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN yum -y install nodejs npm --enablerepo=epel
RUN npm install -g brunch@1.7.17
