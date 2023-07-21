#!/bin/bash

#Base packages
sudo apt update && sudo apt install -y curl net-tools postgresql-client gnupg
sudo hostname ${my_hostname}
