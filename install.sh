#!/bin/bash

sudo sysctl -w vm.max_map_count=262144

echo "1"

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install wget unzip -y

echo "$MY_PWD" |  sudo apt-get install openjdk-11-jdk -y wget unzip
sudo update-alternatives --config java
java -version

echo "2"

echo "$MY_PWD" | sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
sudo apt-get update


echo "3"

sudo apt-get -y install postgresql-13
sudo systemctl enable postgresql.service
sudo systemctl start postgresql.service

#sudo passwd postgres
echo -e "\nCreating sonarqube user on PostgreSQL\n"
sudo -i -u postgres psql -c "CREATE USER sonarqube WITH PASSWORD 'sonarqube';"

echo -e "\nCreating sonarqube DB\n"
sudo -i -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonarqube;"

echo -e "\nGranting privileges to sonarqube user on sonarqube DB\n"
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE "sonarqube" to sonarqube;"

sudo wget -q https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-8.6.1.40680.zip
sudo unzip sonarqube-8.9.1.44547.zip -d /opt/

echo "4"

sudo sed -i -e 's/#sonar.jdbc.username=/sonar.jdbc.username=sonar/g' /opt/sonarqube/conf/sonar.properties
sudo sed -i -e 's/#sonar.jdbc.password=/sonar.jdbc.password=sonarqube/g' /opt/sonarqube/conf/sonar.properties
sudo sed -i -e 's/#sonar.jdbc.url=jdbc:postgresql/sonar.jdbc.url=jdbc:postgresql://localhost/sonardb/g' /opt/sonarqube/conf/sonar.properties
sudo sed -i -e 's/#sonar.web.javaAdditionalOpts=/sonar.web.javaAdditionalOpts=-server/g' /opt/sonarqube/conf/sonar.properties
sudo sed -i -e 's/#wrapper.java.command=/path/to/my/jdk/bin/java/wrapper.java.command=/usr/lib/jvm/java-11-openjdk-amd64/bin/java/g' /opt/s/conf/wrapper.conf

echo "5"

echo "[Unit]
Description=SonarQube service
After=syslog.target network.target
[Service]
Type=forking

ExecStart=
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

User=sonarqube
Group=sonarqube
Restart=on-failure

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/sonar.service

# debug: reload
sudo systemctl daemon-reload

sudo systemctl start sonar
sudo systemctl enable sonar
sudo systemctl status sonar

