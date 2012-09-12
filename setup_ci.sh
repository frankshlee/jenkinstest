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

# File generated by update-locale
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

sudo mv /tmp/locale /etc/default/locale
. /etc/default/locale
exitok $? _____________________loaded_locale_____________________
ls -l /etc/default/locale

cd ~/

# install Jenkins and java stuff for java testing.
if [ ! -d /usr/share/jenkins ]; then
  wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
  exitok $? _____________________added_jenkins_key_to_apt_________o
  grep "deb http://pkg.jenkins-ci.org/debian binary/" /etc/apt/sources.list
  already_there=`echo $?`
  if [ "x$already_there" = "x1" ]; then
    echo "deb http://pkg.jenkins-ci.org/debian binary/" | sudo tee -a /etc/apt/sources.list
  fi
  sudo apt-get update
  sudo apt-get -y install openjdk-6-jre openjdk-6-jdk ant maven2 clamav git curl
  exitok $? ____________installed_openjdk-6_sdk_jre_ant_maven2_clamav_git____________
fi


# install jenkins
sudo apt-get -y install jenkins
if [ $? -ne 0 ]; then
  sudo mkdir /usr/share/jenkins
fi
cd /usr/share/jenkins
# Added "--no-check-certificate" because of the below error:
#ERROR: certificate common name "jenkins-ci.org" doesn't match requested host name "updates.jenkins-ci.org".
#To connect to updates.jenkins-ci.org insecurely, use '--no-check-certificate'.
# also...
# don't check if it exists, because the old version may exist.
#if [ ! -f /usr/share/jenkins/jenkins.war ]; then
/etc/init.d/jenkins status
jenkins_status=`echo $?`
# return 0 is running. return 3 is not running.
if [ $jenkins_status -eq 0 ]; then
  #Jenkins Continuous Integration Server is running with the pid 13591
  # TODO: if jenkins-cli.jar does not exist, get it.
  if [ ! -f /usr/share/jenkins/jenkins-cli.jar ]; then
  	wget -O /usr/share/jenkins/jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar
  fi
  jenkins_version=`java -jar /usr/share/jenkins/jenkins-cli.jar -s http://192.168.2.188:8080/cli version`
  echo "If it just displayed \"Failed to authenticate with your SSH keys.\", please ignore."
  if [ ! -f /usr/share/jenkins/jenkins.war.v$jenkins_version ]; then
        sudo wget -O jenkins.war.newest --no-check-certificate https://updates.jenkins-ci.org/latest/jenkins.war
	/etc/init.d/jenkins stop
  	mv /usr/share/jenkins/jenkins.war /usr/share/jenkins/jenkins.war.v$jenkins_version
  	mv /usr/share/jenkins/jenkins.war.newest /usr/share/jenkins/jenkins.war
  	/etc/init.d/jenkins start
  	sleep 2
  	echo "Grabbing jenkins-cli.jar."
  	wget -O /usr/share/jenkins/jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar
  	exitok $? ____________downloaded_jenkins-cli.jar_______________
  fi
else
  /etc/init.d/jenkins start
  sleep 5
  if [ ! -f /usr/share/jenkins/jenkins-cli.jar ]; then
  	wget -O /usr/share/jenkins/jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar
  fi
  jenkins_version=`java -jar /usr/share/jenkins/jenkins-cli.jar -s http://192.168.2.188:8080/cli version`
  echo "If it just displayed \"Failed to authenticate with your SSH keys.\", please ignore."
  if [ ! -f /usr/share/jenkins/jenkins.war.v$jenkins_version ]; then
  	sudo wget -O jenkins.war.newest --no-check-certificate https://updates.jenkins-ci.org/latest/jenkins.war
  	/etc/init.d/jenkins stop
  	mv /usr/share/jenkins/jenkins.war /usr/share/jenkins/jenkins.war.v$jenkins_version
  	mv /usr/share/jenkins/jenkins.war.newest /usr/share/jenkins/jenkins.war
  	/etc/init.d/jenkins start
  	sleep 2
  	# setup Jenkins. Usually a browser to http://machine:8080 works, and manually configure.
  	# But let's try to do it automatically via cli.
  	echo "Grabbing jenkins-cli.jar."
  	wget -O /usr/share/jenkins/jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar
  	exitok $? ____________downloaded_jenkins-cli.jar_______________
  fi
fi

exitok $? _____________downloaded_latest_jenkins________________
cd ~/


# install for TestSwarm https://github.com/jquery/testswarm
# TODO: include a check here if mysql-server is already installed.
# TODO: If mysql-server is going to be installed, set unattended. It asks for mysql root passwd.
#   http://stackoverflow.com/questions/7739645/install-mysql-on-ubuntu-without-password-prompt
sudo apt-get -y install mysql-server nginx php5
if [ ! -d ~/testswarm ]; then
  git clone https://github.com/jquery/testswarm.git
  sudo cp testswarm/config/nginx-sample.conf /etc/nginx/sites-available/nginx.conf
fi


# The apt-get should have started up Jenkins.
# It takes some time for Jenkins to download the latest plugins
sleep 10
sudo java -jar /usr/share/jenkins/jenkins-cli.jar -s http://localhost:8080 version
echo "If it just displayed \"Failed to authenticate with your SSH keys.\", please ignore."

# Update the Plugins
curl  -L http://updates.jenkins-ci.org/update-center.json | sed '1d;$d' | curl -X POST -H 'Accept: application/json' -d @- http://localhost:8080/updateCenter/byId/default/postBack
#sudo java -jar /usr/share/jenkins/jenkins-cli.jar -s http://localhost:8080 restart
sleep 20
sudo java -jar /usr/share/jenkins/jenkins-cli.jar -s http://localhost:8080 install-plugin cvs subversion translation git github audit-trail createjobadvanced blame-upstream-commiters email-ext statusmonitor all-changes checkstyle dry log-parser pmd violations ws-cleanup clamav ansicolor token-macro maven-plugin instant-messaging xcode-plugin skype-notifier growl ircbot greenballs
echo "If it just displayed \"Failed to authenticate with your SSH keys.\", please ignore."
sleep 60
sudo java -jar /usr/share/jenkins/jenkins-cli.jar -s http://localhost:8080 restart
echo "If it just displayed \"Failed to authenticate with your SSH keys.\", please ignore."
sleep 10

IPADDR=`/sbin/ifconfig | sed '/Bcast/!d' | awk '{print $2}'| awk '{print $2}' FS=":"`
echo "Now open your browser and look at http://${IPADDR}:8080"
