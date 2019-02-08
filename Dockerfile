FROM openjdk:8-jdk

MAINTAINER Bo Wang "bo.wang@albumprinter.com"

RUN df -h

RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    openssh-client ssh-askpass\
    ca-certificates \
    curl \
    git \
    tar zip unzip \
  && rm -rf /var/lib/apt/lists/*

#========================================
# Install Python 3.6.5
#========================================
USER root
ENV PYTHON_VERSION="3.6.5"

#Install core packages
RUN apt-get update
RUN apt-get install -y build-essential checkinstall software-properties-common llvm cmake wget git nano nasm yasm zip unzip pkg-config \
    libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev mysql-client default-libmysqlclient-dev

# Install Python 3.6.5
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz \
    && tar xvf Python-${PYTHON_VERSION}.tar.xz \
    && rm Python-${PYTHON_VERSION}.tar.xz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure \
    && make altinstall \
    && cd / \
    && rm -rf Python-${PYTHON_VERSION}

#========================================
# Install Loadimpact K6
#========================================
#USER root
#RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 379CE192D401AB61
#RUN echo "deb https://dl.bintray.com/loadimpact/deb stable main" | sudo tee -a /etc/apt/sources.list
#RUN apt-get update
#RUN apt-get install k6

#==========
# Gradle
#==========
CMD ["gradle"]

ENV GRADLE_HOME /opt/gradle
ENV GRADLE_VERSION 4.6

ARG GRADLE_DOWNLOAD_SHA256=98bd5fd2b30e070517e03c51cbb32beee3e2ee1a84003a5a5d748996d4b1b915
RUN set -o errexit -o nounset \
	&& echo "Downloading Gradle" \
	&& wget --no-verbose --output-document=gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
	\
	&& echo "Checking download hash" \
	&& echo "${GRADLE_DOWNLOAD_SHA256} *gradle.zip" | sha256sum --check - \
	\
	&& echo "Installing Gradle" \
	&& unzip gradle.zip \
	&& rm gradle.zip \
	&& mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
	&& ln --symbolic "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle \
	\
	&& echo "Adding gradle user and group" \
	&& groupadd --system --gid 1000 gradle \
	&& useradd --system --gid gradle --uid 1000 --shell /bin/bash --create-home gradle \
	&& mkdir /home/gradle/.gradle \
	&& chown --recursive gradle:gradle /home/gradle \
	\
	&& echo "Symlinking root Gradle cache to gradle Gradle cache" \
	&& ln -s /home/gradle/.gradle /root/.gradle

# Create Gradle volume
#USER gradle
VOLUME "/home/gradle/.gradle"
WORKDIR /home/gradle

RUN set -o errexit -o nounset \
	&& echo "Testing Gradle installation" \
	&& gradle --version


#========================================
# OCTO
#========================================
USER root

RUN apt-get update \
  && apt-get install -y libunwind8 apt-transport-https dirmngr \
  && rm -rf /var/lib/apt/lists/*

ENV OCTOPUS_VERSION 4.38.1

RUN mkdir /usr/octopus/ \
    && curl -fsSL https://download.octopusdeploy.com/octopus-tools/$OCTOPUS_VERSION/OctopusTools.$OCTOPUS_VERSION.debian.8-x64.tar.gz | tar xzf - -C /usr/octopus/

ENV PATH="/usr/octopus:${PATH}"

#========================================
# PROGET CONFIG
#========================================
ARG PROGET_USERNAME
ARG PROGET_PASSWORD

ENV PROGET_USERNAME=$PROGET_USERNAME
ENV PROGET_PASSWORD=$PROGET_PASSWORD

COPY NuGet.Config /

#========================================
# Add normal user with passwordless sudo 
#========================================
USER root
RUN useradd jenkins --shell /bin/bash --create-home \
  && usermod -a -G sudo jenkins \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo 'jenkins:secret' | chpasswd


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

ARG VERSION=3.18

RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar

COPY jenkins-slave /usr/local/bin/jenkins-slave

RUN chmod a+rwx /home/jenkins
RUN chmod a+rwx /home/jenkins/.m2
WORKDIR /home/jenkins
USER jenkins

ENTRYPOINT ["/usr/local/bin/jenkins-slave"]
