#!/bin/bash
mkdir actions-runner && cd actions-runner

curl -o /home/ubuntu/actions-runner-linux-x64-2.309.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.309.0/actions-runner-linux-x64-2.309.0.tar.gz

chown ubuntu:ubuntu /home/ubuntu/actions-runner-linux-x64-2.309.0.tar.gz

echo "2974243bab2a282349ac833475d241d5273605d3628f0685bd07fb5530f9bb1a  /home/ubuntu/actions-runner-linux-x64-2.309.0.tar.gz" | shasum -a 256 -c

tar xzf /home/ubuntu/actions-runner-linux-x64-2.309.0.tar.gz -C /home/ubuntu && chown -R ubuntu:ubuntu /home/ubuntu/
whoami
sudo -H -u ubuntu bash -c "/home/ubuntu/config.sh --url https://github.com/rohitrana043/Self-Hosted-GitHub-Runner --token AM7EUNX7R773HCK6PZB2JQLFF75JE --runnergroup Default --name github-runner --labels github-runner --work _work -Y" || (./svc.sh install && sudo ./svc.sh start)

sleep(10)

sudo  ./svc.sh install && sudo ./svc.sh start