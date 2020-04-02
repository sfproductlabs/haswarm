# Install Docker on Debian
# Run this file to install dockerCE with swarm on Debian


#Install the packages necessary to add a new repository over HTTPS:
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common gnupg2

#Import the repository’s GPG key using the following curl command:
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -


#Add the stable Docker APT repository to your system’s software repository list:
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
#$(lsb_release -cs) will return the name of the Debian distribution. In this case, that is buster.

#Update the apt package list and install the latest version of Docker CE (Community Edition):
sudo apt update
sudo apt install docker-ce

#Once the installation is completed the Docker service will start automatically. To verify it type in:
sudo systemctl status docker
