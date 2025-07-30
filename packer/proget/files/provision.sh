sleep 10
# Install and startup docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo docker network create proget

# Mount data from efs
sudo yum install -y amazon-efs-utils
sudo mkdir -p /opt/proget
echo "${EFS_ID} /opt/proget efs _netdev,tls,accesspoint=${EFS_AP} 0 0" |sudo tee --append /etc/fstab
sudo mount -a

# Start mssql container
MSSQL_SA_PASSWORD=$(cat /opt/proget/mssql-pass.txt)
sudo docker run -d \
  --name proget-sql \
  --net=proget \
  --restart=unless-stopped \
  -v /opt/proget/mssql2022-cu10:/var/opt/mssql:Z \
  -e 'ACCEPT_EULA=Y' \
  -e "MSSQL_SA_PASSWORD=`cat /opt/proget/mssql-pass.txt`" \
  -e 'MSSQL_PID=Express' mcr.microsoft.com/mssql/server:2022-CU10-ubuntu-22.04

#Start proget container using latest proget 2025
sleep 10
sudo docker run -d \
  --name=proget \
  --net=proget \
  --restart=unless-stopped \
  -p 80:80 \
  -v proget-packages:/var/proget/packages:Z \
  -v /opt:/buildteam:Z \
  -e PROGET_SQL_CONNECTION_STRING="Data Source=proget-sql; Initial Catalog=proget; User ID=sa; Password=`cat /opt/proget/mssql-pass.txt`; Encrypt=True; TrustServerCertificate=True" \
  proget.inedo.com/productimages/inedo/proget:25
