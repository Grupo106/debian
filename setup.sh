#!/usr/bin/env bash
apt-get update
apt-get upgrade
apt-get install -y python-pip python-dev gcc make libffi-dev libssl-dev
apt-get remove -y python-cryptography
pip install --upgrade setuptools cryptography markupsafe
pip install ansible