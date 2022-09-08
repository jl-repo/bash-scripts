#!/bin/bash
# By Jared Leslie
# Email: jared.leslie@quinticon.com.au
# Date: 08/09/2022
# Version 1.0
# Quinticon M-Track Deployment Script. 
# Works with both Debian and Fedora based distributions. Script validated on Ubuntu Server 22.04 and Redhat Enterprise Linux 8 and 9.


# Variables.
INSTALLFILE="$(ls MigrationTool*)"
FIREWALLD="$(firewall-cmd --state 2>/dev/null)"
FIREWALLUFW="$(ufw status 2>/dev/null | awk '{print $2}')"
SELINUX_STATUS="$(grep "^SELINUX=" /etc/selinux/config 2>/dev/null)"
LOCAL="$(localectl status | grep -o "LANG=en_AU.UTF-8")"
SERVICE_NAME=mtrack
PASSWORD=password
#IP="$(hostname -I | awk '{ print $1 }')"

# User Input Variables.
echo ""
echo "Enter the email for the SSL CSR (Default: person@quinticon.com.au). <Enter> to finalize."
read -r EMAIL
EMAIL="${EMAIL:=person@quinticon.com.au}"
echo "Enter the URL for the SSL CSR (Default: mtrack.example.com). <Enter> to finalize."
read -r COMMONNAME
COMMONNAME="${COMMONNAME:=mtrack.example.com}"
echo "Enter the country code for the SSL CSR (Default: AU). <Enter> to finalize."
read -r COUNTRY
COUNTRY="${COUNTRY:=AU}"
echo "Enter the state for the SSL CSR (Default: New South Wales). <Enter> to finalize."
read -r STATE
STATE="${STATE:=New South Wales}"
echo "Enter the locality for the SSL CSR (Default: Sydney). <Enter> to finalize."
read -r LOCALITY
LOCALITY="${LOCALITY:=Sydney}"
echo "Enter the organization for the SSL CSR (Default: Quinticon Pty Ltd). <Enter> to finalize."
read -r ORGANIZATION
ORGANIZATION="${ORGANIZATION:=Quinticon Pty Ltd}"
echo "Enter the organizationalunit for the SSL CSR (Default: Development). <Enter> to finalize."
read -r ORGANIZATIONALUNIT
ORGANIZATIONALUNIT="${ORGANIZATIONALUNIT:=Development}"
echo ""


# Check if the script is run as root or sudo.
if [ "$(whoami 2> /dev/null)" != "root" ] && [ "$(id -un 2> /dev/null)" != "root" ]; then
      echo "You must be root to run this script! Switch to root or use sudo."
      exit 1
fi

# Check if the M-Track Java file is in the same directory as this script.
if [ -f "${INSTALLFILE}" ]; then
    echo ""
    echo "MigrationTool Java File is located in the same directory as this script. Continuing deployment..."
    echo ""
else
    echo ""
    echo "Migration Tool Java file is not located in the same directory as this script. Please place a copy of .jar file in the same directory as this script."
    exit 1
fi

# Linux Distribution Check.
echo "Check which Linux distribution is in use."
echo ""
if [ -f /etc/redhat-release ] ; then
    PKMGR="$(which yum | grep -o yum)"
    echo "Fedora based distribition. Using yum package manager."
elif [ -f /etc/debian_version ] ; then
    PKMGR="$(which apt-get | grep -o apt)"
    echo "Debian based distribiton. Using apt package manager."
else
    echo "Distribution type not detected. Exiting deployment."
    exit 1
fi

# Install Prereq Software.
if [ "${PKMGR}" = yum ]; then
    echo "Adding neo4j repository..."
    rpm --import https://debian.neo4j.com/neotechnology.gpg.key
    echo -e '[neo4j]\nname=Neo4j Yum Repo\nbaseurl=http://yum.neo4j.com/stable\nenabled=1\ngpgcheck=1' > /etc/yum.repos.d/neo4j.repo
    echo ""
    echo "Installing OpenJava 11, Neo4j and Nginx..."
    yum install neo4j-3.5.5 nginx openssl java-11-openjdk -y # using yum for wider compatibility. has a link to dnf for later distro's.
elif [ "${PKMGR}" = apt ]; then
    echo "Adding neo4j repository..."
    curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key | gpg --dearmor -o /usr/share/keyrings/neo4j.gpg
    echo "deb [signed-by=/usr/share/keyrings/neo4j.gpg] https://debian.neo4j.com stable 3.5" | tee -a /etc/apt/sources.list.d/neo4j.list
    echo "Installing OpenJava 11, Neo4j and Nginx..."
    add-apt-repository universe -y
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common neo4j nginx openssl openjdk-11-jdk openjdk-8-jdk
    systemctl stop neo4j # required as after installation the service starts causing issues with changing the initial password.
    rm -r /var/lib/neo4j/data/dbms/auth # required as after installation the service starts causing issues with changing the initial password.
fi

# Set neo4j initial password.
echo "Set neo4j Initial Password..."
neo4j-admin set-initial-password $PASSWORD

# Enable prereq services.
echo "Enabing neo4j Database for startup..."
systemctl enable --now neo4j
echo ""
systemctl status neo4j --no-pager


# Create the CSR and Private Key request
echo "Creating CSR and Private Key..."
openssl req -newkey rsa:2048 -passout pass:$PASSWORD -keyout /etc/ssl/certs/mtrack.key -out /etc/ssl/certs/mtrack.csr -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORGANIZATIONALUNIT/CN=$COMMONNAME/emailAddress=$EMAIL"

# Create a Self Signed Certificate
echo "Creating an Self-Signed Certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -passin pass:$PASSWORD -key /etc/ssl/certs/mtrack.key -out /etc/ssl/certs/mtrack.cert -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORGANIZATIONALUNIT/CN=$COMMONNAME/emailAddress=$EMAIL"

# Generate a OpenSSL DHPARAM file.
echo "Generate an OpenSSL DHPARAM file..."
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

# Configure Nginx config file.
cat > /etc/nginx/conf.d/${COMMONNAME}.conf << EOF
server {
    listen 80;
    return 301 https://$host$request_uri;
}
server {
    listen 443 http2 ssl;
    listen [::]:443 http2 ssl;
    server_name ${COMMONNAME};
    ssl_certificate /etc/ssl/certs/mtrack.cert;
    ssl_certificate_key /etc/ssl/certs/mtrack.key;
    ssl_password_file /etc/ssl/certs/ssl_passwords.txt;
    ssl_dhparam /etc/ssl/certs/dhparam.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_redirect http://localhost:8080 https://${COMMONNAME};
    }
}
EOF

# Create password file for nginx.
cat > /etc/ssl/certs/ssl_passwords.txt << EOF
${PASSWORD}
EOF
chmod 440 /etc/ssl/certs/ssl_passwords.txt

# Set SELinux Bool for nginx.
if [ "${SELINUX_STATUS}" = SELINUX=enforcing ] || [ "${SELINUX_STATUS}" = SELINUX=permissive ]; then
    echo "Setting SELinux configuration..."
    setsebool -P httpd_can_network_connect 1
else
    echo "SELinux is disabled or not configured."
fi



echo "Enabing nginx for startup..."
systemctl enable --now nginx
echo ""
systemctl status nginx --no-pager
# Required for Debian based systems to pickup the new config where Nginx is already started.
if [ "${PKMGR}" = apt ]; then
    echo "Restarting Nginx..."
    systemctl restart nginx
fi
echo ""
systemctl status nginx

# Set Java Version for Redhat systems.
if [ "${PKMGR}" = yum ]; then
    echo "Choose the Java version for M-Track..."
    alternatives --config java
fi
echo ""
java --version

# Create user and group
echo "Creating required user..."
useradd mtrack

# Create and configure directories.
echo "Creating and configuring required directories..."
mkdir -p /opt/migrationtool/
mkdir -p /etc/migrationtool/
chown mtrack /etc/migrationtool
chmod 660 /etc/migrationtool
mkdir -p /var/migrationtool/pngFiles/
chown mtrack /var/migrationtool
chmod -R 660 /var/migrationtool

# Copy M-Track JAR from source to dest.
cp MigrationTool* /opt/migrationtool/MigrationTool.jar
chown -R mtrack /opt/migrationtool/
chmod 550 /opt/migrationtool/MigrationTool.jar

# Check and set language.
if [ "$LOCAL" != LANG=en_AU.UTF-8 ]; then
    echo "Setting Language to en_AU.UTF-8..."
    localectl set-locale LANG="en_AU.UTF-8"
fi

# Setting firewall rules for M-Track.
if [ "${FIREWALLD}" = running ] || [ "${PKMGR}" = yum ]; then
    echo "Adding Firewall Rules..."
    firewall-cmd --add-service=https --permanent
    echo "Reloading Firewalld"
    firewall-cmd --reload
elif [ "${FIREWALLUFW}" = active ] || [ "${PKMGR}" = apt ]; then
    echo "Adding Firewall Rules..."
    ufw allow 443/tcp
else
    echo "Firewall not enabled."
fi

# Create the environmentfile file.
#echo "Creating environment file..."
#cat > /etc/migrationtool/environmentfile << EOF
#ROOT_DIR=/usr/local/bin
##EXEC_JAR="MigrationTool.jar"
#JAVA_OPS="-Xmx128m"
#WEB_SERVER_PORT="8080"
#USER="mtrack"
#EOF

echo "Creating the application.properties file..."
cat > /opt/migrationtool/application.properties << EOF
mtrack.png-files.location=.
server.address=127.0.0.1
EOF


 # Create Systemd service file.
echo "Creating service file..."
cat > /etc/systemd/system/"${SERVICE_NAME//'"'/}".service << EOF
[Unit] 
Description=M-Track Application
After=network.target 

[Service] 
Type=simple
User=mtrack
WorkingDirectory=/opt/migrationtool/
ExecStart=/usr/bin/java -jar MigrationTool.jar
StandardOutput=journal 
StandardError=journal
SyslogIdentifier=mtrack 
SuccessExitStatus=143 
TimeoutStopSec=10 
Restart=on-failure 
RestartSec=60 

[Install] 
WantedBy=multi-user.target
EOF

# Restart Daemon, Enable and Start M-Track Service.
echo "Reloading daemon and enabling service..."
systemctl daemon-reload 
systemctl enable "${SERVICE_NAME//'.service'/}" # remove the extension
systemctl start "${SERVICE_NAME//'.service'/}"
echo "Waiting 20 seconds for '${SERVICE_NAME}' to start..."
sleep 20 && systemctl status "${SERVICE_NAME//'.service'/}" --no-pager
echo "Service Started."

# M-Track temporary password
#echo "M-Track Temporary Admin Password:"
#curl --insecure https://localhost/wizard/step1 &>/dev/null
#journalctl -u mtrack | grep "Temporary Administrator password :" | awk '{ print $NF }'

# Exit the script.
exit 0