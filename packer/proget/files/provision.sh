sleep 10
#Install and startup docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo docker network create proget

#Mount data from efs
sudo yum install -y amazon-efs-utils
sudo mkdir -p /opt/proget
echo "${EFS_ID} /opt/proget efs _netdev,tls,accesspoint=${EFS_AP} 0 0" |sudo tee --append /etc/fstab
sudo mount -a
sleep 10
sudo docker run --name proget-sql -v /opt/proget/mssql2022:/var/opt/mssql:Z -e 'ACCEPT_EULA=Y' -e "MSSQL_SA_PASSWORD=`cat /opt/proget/mssql-pass.txt`" -e 'MSSQL_PID=Express' --net=proget -d --restart=unless-stopped mcr.microsoft.com/mssql/server:2022-latest
sleep 10
sudo docker run -d -v proget-packages:/var/proget/packages:Z -p 80:80 --net=proget --name=proget -e PROGET_DB_TYPE=SqlServer -e PROGET_DATABASE="Data Source=proget-sql; Initial Catalog=ProGet; User ID=sa; Password=`cat /opt/proget/mssql-pass.txt`" --restart=unless-stopped -v /opt:/buildteam:Z inedo/proget:latest
