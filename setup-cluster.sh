#!/bin/bash
set -x

if [ -z ${1} ]; then
  echo "ERROR: The first argument «gcp account» must be provided"
  exit 1;
fi

for m in {1..3}; do
  docker-machine create -d google --google-project ${1} manager${m}
  declare MANAGER${m}_IP=$(docker-machine ssh manager${m} 'ifconfig eth0 | grep "inet addr:" | cut -d: -f2 | cut -d" " -f1')
  export MANAGER${m}_IP
done
for i in {1..3}; do
  docker-machine create -d google --google-project ${1} worker${i}
  declare WORKER${m}_IP=$(docker-machine ssh worker${m} 'ifconfig eth0 | grep "inet addr:" | cut -d: -f2 | cut -d" " -f1')
  export WORKER${m}_IP
done

docker-machine ssh manager1 sudo docker swarm init --advertise-addr ${MANAGER1_IP}
WORKER_TOKEN=$(docker-machine ssh manager1 sudo docker swarm join-token -q worker)
MANAGER_TOKEN=$(docker-machine ssh manager1 sudo docker swarm join-token -q manager)

for i in {2..3}; do
  docker-machine ssh manager${i} sudo docker swarm join --token ${MANAGER_TOKEN} ${MANAGER1_IP}:2377
done
  

for i in {1..3};do
  docker-machine ssh worker${i} sudo docker swarm join --token ${WORKER_TOKEN} ${MANAGER1_IP}:2377
done

eval $(docker-machine env manager1)
