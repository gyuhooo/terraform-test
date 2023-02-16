#!/bin/sh
##### Instance ID captured through Instance meta data #####
InstanceID=`/usr/bin/curl -s http://169.254.169.254/latest/meta-data/instance-id`
EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"
HOME=/home/ec2-user
##### Set a tag name indicating instance is not configured ####
aws ec2 create-tags --region $EC2_REGION --resources $InstanceID --tags Key=Initialized,Value=false
##### Install Ansible ######
yum update -y
yum install git -y
curl "https://bootstrap.pypa.io/get-pip.py" -o "/tmp/get-pip.py"
amazon-linux-extras install -y python3.8
echo 'alias python=python3.8' >> ~/.bashrc
source ~/.bashrc
python /tmp/get-pip.py
pip install pip --upgrade
rm -fr /tmp/get-pip.py
pip install boto
pip install --upgrade ansible
cd /root
##### Clone your ansible repository ######
git clone https://github.com/gyuhooo/ansible-test.git
cd ansible-test
mkdir /etc/ansible/
cp hosts /etc/ansible/hosts
# chmod 400 keys/*
##### Run your ansible playbook for only autoscaled and not initialised instances ######
ansible-playbook playbook.yml 
##### Update TAG ######
aws ec2 create-tags --region $EC2_REGION --resources $InstanceID --tags Key=Initialized,Value=true