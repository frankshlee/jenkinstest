#!/bin/bash
set -x

GROOVY_HOME="/usr/share/groovy"
JAVA_HOME="/usr/lib/jvm/java-6-openjdk"


# 2012/08/07 Frank Lee
# This assumes that this script will be run on 
# a freshly installed Debian 6 install.


function exitok() {
	status=$1
	job=$2
	if [ $status -ne 0 ]; then
		echo "Exiting from $2.  Errored with $status."
		exit $1
	else
		echo "Job: $2 is ok with status $1. Continuing."
	fi
}

#  File generated by update-locale
# Fix locale /etc/default/locale
if [ -f /etc/default/locale ]; then
	sudo mv /etc/default/locale /etc/default/locale.backup.`date +%Y%m%d%H%M%S`
	exitok $? _______________created_locale__________________
fi

cat > /tmp/locale <<EOF
LANG="en_US.UTF-8"
LANGUAGE="en_US:en"
LC_ALL="en_US.UTF-8"
LC_CTYPE="en_US.UTF-8"
EOF
exitok $? _____________________created_locale__________________
ls -l /tmp/locale

sudo mv /tmp/locale /etc/default/locale
. /etc/default/locale
exitok $? _____________________loaded_locale_____________________
ls -l /etc/default/locale

cd ~/

# install Jenkins and java stuff for java testing.
wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
exitok $? _____________________added_jenkins_key_to_apt_________o
echo "deb http://pkg.jenkins-ci.org/debian binary/" | sudo tee -a /etc/apt/sources.list
sudo apt-get update
sudo apt-get -y install openjdk-6-jre openjdk-6-jdk ant maven2 clamav git curl
exitok $? ____________installed_openjdk-6_sdk_jre_ant_maven2_clamav_git____________

# remove jenkins if it's already install.
# well, let's get back to this later.
#sudo apt-get -y --purge remove jenkins

# install jenkins
sudo apt-get -y install jenkins
if [ $? -ne 0 ]; then
  sudo mkdir /usr/share/jenkins
fi
cd /usr/share/jenkins
if [ ! -f /usr/share/jenkins/jenkins.war ]; then
  sudo wget http://updates.jenkins-ci.org/download/war/1.476/jenkins.war
fi
exitok $? _____________downloaded_jenkins_1.476_______________
cd ~/


# install for TestSwarm https://github.com/jquery/testswarm
sudo apt-get -y install mysql-server nginx php5
if [ ! -d ~/testswarm ]; then
  git clone https://github.com/jquery/testswarm.git
  sudo cp testswarm/config/nginx-sample.conf /etc/nginx/sites-available/nginx.conf
fi

# setup Jenkins. Usually a browser to http://machine:8080 works, and manually configure.
# But let's try to do it automatically via cli.
if [ ! -f ~/jenkins-cli.jar ]; then
  cd ~/
  echo "The jenkins-cli.jar doesn't exist. Grabbing it."
  wget http://localhost:8080/jnlpJars/jenkins-cli.jar
  exitok $? ____________downloaded_jenkins-cli.jar_______________
fi

# The apt-get should have started up Jenkins.
# It takes some time for Jenkins to download the latest plugins
sleep 10
sudo java -jar ~/jenkins-cli.jar -s http://localhost:8080 version
# Update the Plugins
curl  -L http://updates.jenkins-ci.org/update-center.json | sed '1d;$d' | curl -X POST -H 'Accept: application/json' -d @- http://localhost:8080/updateCenter/byId/default/postBack
#sudo java -jar ~/jenkins-cli.jar -s http://localhost:8080 restart
sleep 20
sudo java -jar ~/jenkins-cli.jar -s http://localhost:8080 install-plugin cvs subversion translation git github audit-trail createjobadvanced blame-upstream-commiters email-ext statusmonitor all-changes checkstyle dry log-parser pmd violations ws-cleanup clamav ansicolor token-macro maven-plugin instant-messaging xcode-plugin skype-notifier growl ircbot
sleep 60
sudo java -jar ~/jenkins-cli.jar -s http://localhost:8080 restart
sleep 10

IPADDR=`/sbin/ifconfig | sed '/Bcast/!d' | awk '{print $2}'| awk '{print $2}' FS=":"`
echo "Now open your browser and look at http://${IPADDR}:8080"

