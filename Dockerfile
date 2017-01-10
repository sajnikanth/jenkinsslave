FROM cloudbees/java-build-tools

USER root

#====================================
# Clone product and install java depedencies
# https://github.com/albumprinter/FitNesseTestFramework.git
#====================================
# Make ssh dir
#RUN mkdir /root/.ssh/


# Copy over private key, and set permissions
#ADD id_rsa /root/.ssh/id_rsa
#RUN chmod 600 /root/.ssh/id_rsa

# Create known_hosts
#RUN touch /root/.ssh/known_hosts
# Add bitbuckets key
#RUN ssh-keyscan github.com >> /root/.ssh/known_hosts

# Clone the conf files into the docker container
#RUN git clone git@github.com:albumprinter/FitNesseTestFramework.git /root/repo

#RUN cd /root/repo && mvn install -Dmaven.test.skip=true
#RUN rm -rf /root/repo
#====================================
# Install Jars
# serenity-core-1.1.42.jar
#====================================
#COPY serenity-core-1.1.42.jar /usr/local/serenity-core-1.1.42.jar
#RUN  mvn install:install-file -Dfile=/usr/local/serenity-core-1.1.42.jar -DgroupId=net.serenity-bdd -DartifactId=serenity-core -Dversion=1.1.42 -Dpackaging=jar

#====================================
# Copy dependencies to jenkins user
# 
#====================================
#RUN cp -a /root/.m2 /home/jenkins/.m2
#RUN chown -R jenkins /home/jenkins/.m2
#RUN rm -rf /root/.m2

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
WORKDIR /home/jenkins
USER jenkins

ENTRYPOINT ["/opt/bin/entry_point.sh", "/usr/local/bin/jenkins-slave"]
