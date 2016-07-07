#!env /bin/sh
apt-get update
apt-get upgrade
apt-get install -y python-pip python-dev gcc make libffi-dev libssl-dev
apt-get remove python-cryptography
pip install --upgrade setuptools cryptography markupsafe
pip install ansible
