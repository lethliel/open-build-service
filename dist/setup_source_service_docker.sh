#!/bin/bash

DAEMON_UID=2
DAEMON_GID=2

BRAND_STRING=$( cat /etc/SUSE-brand )
BRAND=$( echo $BRAND_STRING | cut -d ' ' -f1 )
SUSE=$( echo $BRAND | cut -d ' ' -f1 )
VERSION=$( echo $BRAND_STRING | cut -d ' ' -f4 )

repo=$SUSE"_"$VERSION
docker_image="suse/obs-source-service:latest"

if [ "$SUSE" == "openSUSE" ]; then
  downloadserver="download.opensuse.org/repositories"
  echo "Adding repository for docker containers"
  sudo zypper ar --refresh -n --no-gpg-checks http://download.opensuse.org/repositories/Virtualization:/containers/$SUSE"_Leap_"$VERSION/Virtualization:containers.repo
  echo "Adding repository for source service containment"
  sudo zypper ar --refresh -n --no-gpg-checks -t rpm-md http://download.opensuse.org/repositories/OBS:/Server:/Unstable/containment/ Containment
  docker_install="obs-source-service-docker-image"
elif [ "$SUSE" == "SLE" ]; then
  echo "SLE not supported yet by the installer"
  exit
  # If we are on a SLE the download server and repositories must be different. 
  # Must be clarified. Until clarification the installer only works on openSUSE Distributions.
else   
  echo "Something wrong with the OS brand. Must be SLE or openSUSE."
  exit
fi

echo "Adding main obs repository"
sudo zypper ar --refresh -n --no-gpg-checks http://$downloadserver/OBS:/Server:/Unstable/$repo/OBS:Server:Unstable.repo


# Install the software we need
echo "Installing required software"
zypper -n remove kernel-default-base
zypper -n install kernel-default
zypper -n install obs-server obs-source_service perl-XML-Structured acl
zypper -n install docker sle2docker

echo "creating run directory for service"
mkdir -p /srv/obs/run
chown obsrun:obsrun /srv/obs/run

echo "set extended acl feature on /srv/obs/run/"
setfacl -m u:obsservicerun:rwx /srv/obs/run/


echo "Setting correct bsservicegroup"
if grep -q "^our \$bsservicegroup =.*" /usr/lib/obs/server/BSConfig.pm; then
  echo "Changing service group ..."
  sed -i "s,^our \$bsservicegroup =.*,our \$bsservicegroup = 'docker';," /usr/lib/obs/server/BSConfig.pm
fi

echo "Setting service wrapper"
if ! grep -q "^our \$service_wrapper =.*" /usr/lib/obs/server/BSConfig.pm; then
  echo "No service wrapper defined. We must create one..."
  echo "our \$service_wrapper = { '*' => '/usr/lib/obs/server/call-service-in-docker.sh' };1;" >> /usr/lib/obs/server/BSConfig.pm
fi

echo "Setting docker image"
if ! grep -q "^our \$docker_image =.*" /usr/lib/obs/server/BSConfig.pm; then
  echo "No docker image configured. Will configure the docker image..."
  echo "our \$docker_image = 'suse/obs-source-service:latest';1;" >> /usr/lib/obs/server/BSConfig.pm
fi

echo "Altering default docker opts"
sed -i 's,DOCKER_OPTS=.*, DOCKER_OPTS="--userns-remap=obsservicerun:obsrun",' /etc/sysconfig/docker

echo "creating subuid and subgid"
echo "obsservicerun:"$(($( id -u obsservicerun ) - $DAEMON_UID ))":65536" >> /etc/subuid
echo "obsrun:"$(($( id -g obsservicerun ) - $DAEMON_GID ))":65536" >> /etc/subgid

echo "enable and start docker"
systemctl enable docker
systemctl start docker

echo "enable and start obsservice"
systemctl enable obsservice
systemctl start obsservice

echo "install and register containment"
zypper -n install --replacefiles $docker_install
