#!/bin/bash
set -x
#-------- Docker Installation ----------#
bash <(curl -s https://raw.githubusercontent.com/docker/docker-install/master/install.sh)
sudo usermod -aG docker ubuntu
newgrp docker
#-------- Run Graphite and Grafana Containers ----------#
docker run -d --name graphite --restart=always -p 80:80 -p 8080:8080 -p 2003-2004:2003-2004 -p 2023-2024:2023-2024 -p 8125:8125/udp -p 8126:8126 graphiteapp/graphite-statsd
docker run -d --name=grafana -p 3000:3000 grafana/grafana
#-------- Run Prometheus and Blackbox Exporter ----------#
docker run -d --name prometheus-container -e TZ=UTC -p 9090:9090 ubuntu/prometheus:2.46.0-22.04_stable
docker run -d -p 9115:9115/tcp --name blackbox_exporter quay.io/prometheus/blackbox-exporter:latest
#-------- GitHub Runner Installation --------#
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.310.2.tar.gz -L https://github.com/actions/runner/releases/download/v2.310.2/actions-runner-linux-x64-2.310.2.tar.gz
echo "fb28a1c3715e0a6c5051af0e6eeff9c255009e2eec6fb08bc2708277fbb49f93  actions-runner-linux-x64-2.310.2.tar.gz" | shasum -a 256 -c
mv actions-runner-linux-x64-2.310.2.tar.gz /home/ubuntu/ && chown ubuntu:ubuntu /home/ubuntu/actions-runner-linux-x64-2.310.2.tar.gz
tar xzf /home/ubuntu/actions-runner-linux-x64-2.310.2.tar.gz -C /home/ubuntu && chown -R ubuntu:ubuntu /home/ubuntu/
sudo -H -u ubuntu bash -c "/home/ubuntu/config.sh --url https://github.com/githubon2024 --token AESNUZWIYU3CN2R3QSVSNLTFKB4VS --runnergroup Default --name linux-uat-1 --labels linux-uat-1 --work _work"
while [ ! -f /home/ubuntu/svc.sh ]; do sleep 10; done
sudo /home/ubuntu/svc.sh install && sudo /home/ubuntu/svc.sh start