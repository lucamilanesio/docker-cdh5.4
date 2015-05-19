#!/bin/bash

yum -y update;
yum -y clean all; 

# Installing necessary tools
yum -y clean all; yum install -y java-1.7.0-openjdk wget dialog curl sudo lsof vim axel telnet java-1.7.0-openjdk java-1.7.0-openjdk-devel

# Adding cloudera repos
wget http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/cloudera-cdh5.repo
mv cloudera-cdh5.repo /etc/yum.repos.d/cloudera-cdh5.repo
rpm --import http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/RPM-GPG-KEY-cloudera

# Installing hadoop
yum -y clean all; yum install -y hadoop-yarn-resourcemanager hadoop-hdfs-namenode hadoop-hdfs-secondarynamenode hadoop-yarn-nodemanager hadoop-hdfs-datanode hadoop-mapreduce hadoop-mapreduce-historyserver hadoop-yarn-proxyserver hadoop-client

# Installing Impala
yum -y clean all; yum install -y hadoop-conf-pseudo impala impala-server impala-state-store impala-catalog impala-shell

# Moving Security file to perform action as hdfs user /etc/security/limits.d/hdfs.conf 
mv /etc/security/limits.d/hdfs.conf ~/
mv /etc/security/limits.d/mapreduce.conf ~/
mv /etc/security/limits.d/yarn.conf ~/

#CDH5-Installation-Guide Step 1 - Format the NameNode
echo "Step 1 - Format the NameNode"
su - hdfs -c 'hdfs namenode -format'

#CDH5-Installation-Guide Step 2 - Start HDFS
echo "Step 2 - Start HDFS"
bash -c 'for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do service $x start ; done'

#CDH5-Installation-Guide Step 3 - Create the directories needed for Hadoop processes
echo "Step 3 - Create the directories needed for Hadoop processes"
/usr/lib/hadoop/libexec/init-hdfs.sh

#CDH5-Installation-Guide Step 4: Verify the HDFS File Structure
echo "Step 4: Verify the HDFS File Structure"
su - hdfs -c 'hadoop fs -ls -R /'

#CDH5-Installation-Guide Step 5 - Start Yarn
echo "Step 5 - Start Yarn"
service hadoop-yarn-resourcemanager start
service hadoop-yarn-nodemanager start
service hadoop-mapreduce-historyserver start

#CDH5-Installation-Guide Step 6 - Create User Directories
echo "Step 6 - Create User Directories"

su - hdfs -c 'hadoop fs -chmod a+w /'
su - hdfs -c 'hadoop fs -mkdir -p /user/hadoop'
su - hdfs -c 'hadoop fs -chmod a+w /user'
su - hdfs -c 'hadoop fs -chown hadoop /user/hadoop'

hadoop fs -chmod g+w   /tmp
hadoop fs -mkdir -p /user/hive/warehouse
hadoop fs -chmod g+w   /user/hive/warehouse

#Satish: Changing warehouse permissions
hadoop fs -chmod -R a+w /user/hive/warehouse
hadoop fs -chmod -R a+w /user/hive/warehouse/*

# Adding Hbase dir
su - hdfs -c 'hadoop fs -mkdir /hbase'
su - hdfs -c 'hadoop fs -chown hbase /hbase'
su - hdfs -c 'hadoop fs -chmod a+w /hbase'

# Moving security file back to its location
mv ~/hdfs.conf /etc/security/limits.d/
mv ~/mapreduce.conf /etc/security/limits.d/
mv ~/yarn.conf /etc/security/limits.d/

#CDH5-Installation-Guide Install HBase
echo "Install Cloudera Components"
#Satish: Added zookeeper
yum install -y zookeeper zookeeper-server hive hbase hbase-thrift hbase-master pig oozie oozie-client spark-core spark-master spark-worker spark-history-server spark-python hue hue-server

#Initiate Oozie Database
oozie-setup db create -run

#Create HUE Secret Key
sed -i 's/secret_key=/secret_key=_S@s+D=h;B,s$C%k#H!dMjPmEsSaJR/g' /etc/hue/conf/hue.ini