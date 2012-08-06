#!/bin/bash

# 2012/08/07 Frank Lee
# This assumes that this script will be run on 
# a freshly installed Debian 6 install.


#  File generated by update-locale
# Fix locale /etc/defaults/locale
cat << ++
LANG="en_US.UTF-8"
LANGUAGE="en_US:en"
LC_ALL="en_US.UTF-8"
LC_CTYPE="en_US.UTF-8"
++ > /etc/defaults/locale
. /etc/defaults/locale

cd /root

# install Jenkins and java stuff for java testing.
sudo apt-get -y install sudo git
wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
sudo echo "deb http://pkg.jenkins-ci.org/debian binary/" >> /etc/apt/sources.list
sudo apt-get update
sudo apt-get -y install jenkins openjdk-6-jre openjdk-6-jdk ant maven2 clamav
cd /usr/share/jenkins
wget http://updates.jenkins-ci.org/download/war/1.476/jenkins.war
cd -


# install for TestSwarm https://github.com/jquery/testswarm
sudo apt-get -y install mysql-server nginx php5
git clone https://github.com/jquery/testswarm.git
sudo cp testswarm/config/nginx-sample.conf /etc/nginx/sites-available/

# setup Jenkins. Usually a browser to http://machine:8080 works, and manually configure.
# But let's try to do it automatically via cli.

wget http://localhost:8080/jnlpJars/jenkins-cli.jar
java -jar jenkins-cli.jar -s http://localhost:8080 install-plugin \
cvs subversion translation git github audit-trail createjobadvanced blame-upstream-commiters email-ext statusmonitor all-changes checkstyle dry log-parser pmd violations ws-cleanup clamav ansicolor 
java -jar jenkins-cli.jar -s http://localhost:8080 restart
