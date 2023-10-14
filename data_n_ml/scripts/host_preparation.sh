#!/bin/bash
bash <(curl -s https://raw.githubusercontent.com/docker/docker-install/master/install.sh)
sudo usermod -aG docker ubuntu
newgrp docker