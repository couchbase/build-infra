#!/bin/bash
set -x
instance_id="`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id || die \"wget instance-id has failed: $?\"`"
instance_ip="`wget -q -O - http://169.254.169.254/latest/meta-data/local-ipv4 || die \"wget local-ipv4 has failed: $?\"`"

yum install -y jq

#register to cloudmap
service_id=`aws servicediscovery list-services --region us-east-1 |jq -r '.Services[] | select(.Name | contains("proget.build") ) | .Id'`
old_instance=`aws servicediscovery list-instances --service-id=srv-pwxkawsumuqeaauu --region=us-east-1 |jq ".Instances[].Id"`
aws servicediscovery deregister-instance --service-id $service_id --instance-id $old_instance --region us-east-1
aws servicediscovery register-instance --service-id $service_id --instance-id $instance_id --attributes=AWS_INSTANCE_IPV4=$instance_ip --region us-east-1

#create EFS mount
mount -t efs -o iam,tls,accesspoint=${proget_accesspoint} ${filesystem}: /opt/proget

cd /opt/proget
systemctl enable docker
systemctl start docker
docker network create proget
docker run --name proget-sql -e 'ACCEPT_EULA=Y' -e "MSSQL_SA_PASSWORD=`cat mssql-pass.txt`" -e 'MSSQL_PID=Express' -v /opt/proget/mssql:/var/opt/mssql --net=proget --restart=unless-stopped -d mcr.microsoft.com/mssql/server:2017-latest
docker run -d -v proget-packages:/var/proget/packages -p 80:80 --net=proget --name=proget -e PROGET_DB_TYPE=SqlServer -e PROGET_DATABASE="Data Source=proget-sql; Initial Catalog=ProGet; User ID=sa; Password=`cat mssql-pass.txt`" --restart=unless-stopped -v /opt/proget:/buildteam/proget inedo/proget:latest
