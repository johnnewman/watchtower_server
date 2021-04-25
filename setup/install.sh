# install.sh
#
# John Newman
# 2021-04-25
#
# This script only needs to be run once. This will set up everything Watchtower
# Server needs so that you simply need to run `docker-compose build` and
# `docker-compose up -d`.
#
# In summary, this script:
# - configures a Firewall to only allow HTTPS and SSH traffic.
# - installs docker and docker-compose.
# - creates a new "wtmonitor" group to communicate with the Vapor server.
# - updates the .env file with the new group id.
# - enables a systemd service for detecing when nginx needs to be restarted after a config change.
#
# The current user is added to both the docker and wtmonitor groups


set -e

WATCHTOWER_PATH=`dirname "$(dirname "$(readlink -f "$0")")"`

sudo apt update
sudo apt upgrade -y
sudo apt install -y ufw

# Install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh 
rm get-docker.sh

# Install docker-compose
sudo pip3 -v install docker-compose

# Add user to the docker group
sudo usermod -aG docker $USER
echo "Installed docker and docker-compose. Current user is now in the \"docker\" group."

# Set up ufw
echo "Creating firewall rules to allow http(s) traffic and ssh access..."
sudo ufw enable
sudo ufw allow '80'
sudo ufw allow '443'
sudo ufw allow 'ssh'

# Create group for unix socket read/write access.
sudo groupadd wtmonitor
sudo usermod -a -G wtmonitor $USER
WT_MONITOR_GID=`getent group wtmonitor | awk -F: '{printf "%d", $3}'`
echo "Created wtmonitor group with gid: $WT_MONITOR_GID"

# Add the wtmonitor group to env file.
sed -i "s,<socket_gid>,$WT_MONITOR_GID", "$WATCHTOWER_PATH/.env"

# Install wtmonitor service.
sed -i".bak" "s,<user>,$USER,g ; s,<watchtower_path>,$WATCHTOWER_PATH,g" "$WATCHTOWER_PATH/setup/wtmonitor.service"
sudo ln -s "$WATCHTOWER_PATH/setup/wtmonitor.service" "/etc/systemd/system/"
sudo systemctl enable wtmonitor.service
echo "Created systemd wtmonitor.service file and configured it to run on boot."
echo "\n\nInstallation finished! Final steps to take:

REQUIRED:
1) Upload SSL certificates to \"$WATCHTOWER_PATH/certs/\". You will need:
        a) A public SSL certificate for encrypting traffic (SSL_CERT in .env).
        b) The corresponding private key for encrypting traffic (SSL_KEY in .env).
        c) A certificate authority cert for validating clients and upstream certs (CLIENT_VERIFY_CA and UPSTREAM_CA in .env).
        d) A client cert for authenticating with upstream clients (CLIENT_CERT in .env).
        e) A client key for authenticating with upstream clients (CLIENT_KEY in .env).
2) Update the public host name of the server (HOST_NAME in .env).
3) Restart the system and run 'docker-compose build' and 'docker-compose up -d'
"