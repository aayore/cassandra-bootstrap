#!/bin/bash

# Set up logging to /var/log/syslog and /var/log/user-data.log (and console)
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Grab updates and AWS CLI (for subsequent S3 access)..."
apt-get update
apt-get upgrade -y
apt-get install -y awscli

echo "Grab the packages we need for our Cassandra installation..."
aws s3 cp s3://ello-dev-us-east-1/bootstrap/cassandra/apache-cassandra-2.1.3-bin.tar /tmp/ --region=us-east-1
aws s3 cp s3://ello-dev-us-east-1/bootstrap/cassandra/server-jre-7u76-linux-x64.tar /tmp/ --region=us-east-1

echo "Install Oracle Java..."
mkdir -p /usr/lib/jvm
tar xf /tmp/server-jre-7u76-linux-x64.tar -C /usr/lib/jvm/
ln -s /usr/lib/jvm/jdk1.7.0_76/ /usr/lib/jvm/jdk
update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/jdk/bin/java" 1
update-alternatives --set java /usr/lib/jvm/jdk/bin/java
java -version

echo "Install Cassandra..."
tar xf /tmp/apache-cassandra-2.1.3-bin.tar -C /opt/
ln -s /opt/apache-cassandra-2.1.3/ /opt/cassandra
ls /opt/cassandra

for ip in $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
	do  sed -i -- "s/^listen_address:\ 127.0.0.1/listen_address:\ $ip/" /opt/cassandra/conf/cassandra.yaml
done

echo "Starting Cassandra..."
/opt/cassandra/bin/cassandra

echo "Clean up the installers..."
rm /tmp/apache-cassandra-2.1.3-bin.tar
rm /tmp/server-jre-7u76-linux-x64.tar
