#!/bin/bash

sudo sysctl -w vm.max_map_count=262144

echo -e "\e[1;34m 1. Updating Packages and Installing Dependencies.\e[0m"

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install wget unzip -y

echo "$MY_PWD" |  sudo apt-get install openjdk-11-jdk -y wget unzip
sudo update-alternatives --config java
java -version

echo -e "\e[1;34m 2. Installing PostgreSQL. Please Wait...\e[0m"

echo "$MY_PWD" | sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
sudo apt-get update


echo -e "\e[1;34m 3. Starting PostgreSQL.....\e[0m"
sudo apt-get -y install postgresql-13
sudo systemctl enable postgresql.service
sudo systemctl start postgresql.service

#sudo passwd postgres
echo -e "\e[1;34m 4. Creating User, Password and Database in PostgreSQL.\e[0m"
echo -e "\nCreating sonarqube DB\n"
sudo -i -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonarqube;"

echo -e "\nGranting privileges to sonarqube user on sonarqube DB\n"
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE "sonarqube" to sonarqube;"

echo -e "\e[1;34m 5. Installing SonarQube. Please Wait....\e[0m"
sudo wget -q https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-8.6.1.40680.zip 
sudo unzip sonarqube-8.6.1.40680.zip -d  /opt/
sudo chown -R sonarqube. /opt/sonarqube-8.6.1.40680

echo -e "\e[1;34m 6. Updating the SonarQube Configuration. Please wait....\e[0m"

sudo sed -i -e 's/#sonar.jdbc.username=/sonar.jdbc.username=sonarqube/g' /opt/sonarqube-8.6.1.40680/conf/sonar.properties
sudo sed -i -e 's/#sonar.jdbc.password=/sonar.jdbc.password=sonarqube/g' /opt/sonarqube-8.6.1.40680/conf/sonar.properties
sudo sed -i -e 's/#sonar.jdbc.url=jdbc:postgresql/=sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube/g' /opt/sonarqube-8.6.1.40680/conf/sonar.properties
sudo sed -i -e 's/#sonar.web.javaAdditionalOpts=/sonar.web.javaAdditionalOpts=-server/g' /opt/sonarqube-8.6.1.40680/conf/sonar.properties
sudo sed -i -e 's/#sonar.web.host=/sonar.web.host=127.0.0.1/g' /opt/sonarqube-8.6.1.40680/conf/sonar.properties
sudo sed -i -e 's/#wrapper.java.command=/path/to/my/jdk/bin/java/wrapper.java.command=/usr/lib/jvm/java-11-openjdk-amd64/bin/java/g' /opt/sonarqube-8.6.1.40680/conf/wrapper.conf

echo -e "\e[1;34m 7. Creating SonarQube Service.\e[0m"

echo "[Unit]
Description=SonarQube service
After=syslog.target network.target
[Service]
Type=forking

ExecStart=/opt/sonarqube-8.6.1.40680/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube-8.6.1.40680/bin/linux-x86-64/sonar.sh stop

User=sonarqube
Group=sonarqube
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/sonar.service

# debug: reload
sudo systemctl daemon-reload
echo -e "\e[1;34m 8. Starting SonarQube.....\e[0m"
sudo systemctl start sonar
sudo systemctl enable sonar
#sudo systemctl status sonar
echo -e "\e[1;34m Do you want to check status of SonarQube? Default Y.\e[0m"
read -p "Enter Y/N: " value
if [ "${value^^}" == "Y" ];
then
    sudo systemctl status sonar
else
    echo -e "\e[1;34m Exiting....\e[0m"
fi

echo -e "\e[1;34m SonarQube has been installed Successfully\e[0m"