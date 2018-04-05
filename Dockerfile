FROM microsoft/dotnet:2.0-sdk AS builder

ENV DOTNET_CLI_TELEMETRY_OPTOUT 1
ENV DOTNET_SKIP_FIRST_TIME_EXPERIENCE 1

RUN apt-get update \
  && apt-get install -y \
    openssh-client ssh-askpass\
    ca-certificates \
    default-jre \
    zip \
    curl \
    git \
  && rm -rf /var/lib/apt/lists/* 

#========================================
# Add normal user with passwordless sudo
#========================================
RUN useradd jenkins --shell /bin/bash --create-home \
  && usermod -a -G sudo jenkins \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo 'jenkins:secret' | chpasswd

#========================================
# Octopus tools cli
#========================================
ENV OCTOPUS_VERSION 4.31.7

RUN mkdir /usr/octopus/ \
    && curl -fsSL https://download.octopusdeploy.com/octopus-tools/$OCTOPUS_VERSION/OctopusTools.$OCTOPUS_VERSION.debian.8-x64.tar.gz | tar xzf - -C /usr/octopus/ 

ENV PATH="/usr/octopus:${PATH}"

#========================================
# Jenkins Slave
#========================================
ARG JENKINS_SLAVE_VERSION=3.18

RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${JENKINS_SLAVE_VERSION}/remoting-${JENKINS_SLAVE_VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar

COPY jenkins-slave /usr/local/bin/jenkins-slave

RUN chmod a+rwx /home/jenkins
WORKDIR /home/jenkins
USER jenkins

ENTRYPOINT ["/usr/local/bin/jenkins-slave"]
