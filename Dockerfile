FROM openjdk:8-jdk

MAINTAINER Bo Wang "bo.wang@albumprinter.com"

RUN df -h

RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    openssh-client ssh-askpass\
    ca-certificates \
    curl \
    git \
    python python-pip groff \
    python-setuptools\
  && rm -rf /var/lib/apt/lists/* 
 
#==========
# Maven
#==========
ENV MAVEN_VERSION 3.3.9

RUN curl -fsSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven

#========================================
# Add normal user with passwordless sudo
#========================================
RUN useradd jenkins --shell /bin/bash --create-home \
  && usermod -a -G sudo jenkins \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo 'jenkins:secret' | chpasswd

#====================================
# AWS CLI
#====================================
RUN pip install awscli


# compatibility with CloudBees AWS CLI Plugin which expects pip to be installed as user
RUN mkdir -p /home/jenkins/.local/bin/ \
  && ln -s /usr/bin/pip /home/jenkins/.local/bin/pip \
  && chown -R jenkins:jenkins /home/jenkins/.local

USER root
#====================================
# Add local maven repository setting file
#
#====================================
ADD settings.xml /home/jenkins/.m2/settings.xml
RUN chmod 777 /home/jenkins/.m2/settings.xml

#COPY credentials /home/jenkins/.aws/credentials
#RUN chmod 777 /home/jenkins/.aws/credentials
#COPY config /home/jenkins/.aws/config
#RUN chmod 777 /home/jenkins/.aws/config


#====================================
# Setup Jenkins Slave
#
#====================================

ARG VERSION=2.62

RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar

COPY jenkins-slave /usr/local/bin/jenkins-slave

RUN chmod a+rwx /home/jenkins
RUN chmod a+rwx /home/jenkins/.m2
WORKDIR /home/jenkins
USER jenkins

ENTRYPOINT ["/usr/local/bin/jenkins-slave"]
