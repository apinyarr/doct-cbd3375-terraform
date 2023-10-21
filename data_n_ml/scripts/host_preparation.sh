#!/bin/bash
#-------- Docker Installation ----------#
bash <(curl -s https://raw.githubusercontent.com/docker/docker-install/master/install.sh)
sudo usermod -aG docker ubuntu
newgrp docker
#-------- GitHub Runner Installation --------#
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.309.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.309.0/actions-runner-linux-x64-2.309.0.tar.gz
echo "2974243bab2a282349ac833475d241d5273605d3628f0685bd07fb5530f9bb1a  actions-runner-linux-x64-2.309.0.tar.gz" | shasum -a 256 -c
mv actions-runner-linux-x64-2.309.0.tar.gz /home/ubuntu/ && chown ubuntu:ubuntu /home/ubuntu/actions-runner-linux-x64-2.309.0.tar.gz
tar xzf /home/ubuntu/actions-runner-linux-x64-2.309.0.tar.gz -C /home/ubuntu && chown -R ubuntu:ubuntu /home/ubuntu/
sudo -H -u ubuntu bash -c "/home/ubuntu/config.sh --url https://github.com/apinyarr/doct-cbd3375-dataprocessing --token AESNUZQ56NWHEIJQ4QZFILLFGPMM2 --runnergroup Default --name linux --labels linux --work _work"
sudo  ./svc.sh install && sudo ./svc.sh start