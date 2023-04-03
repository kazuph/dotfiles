#!/bin/bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt install -y uidmap
sudo dockerd-rootless-setuptool.sh install

