#!/bin/bash
set -e
#set -x

usage()
{
    cat << EOF
Run DockerSwarm nodes on GCE

Usage : $(basename $0) -p <google_project> -m <managers_count> -w <workers_count>
      -h | --help          : Show this message
      -p | --project       : Google Project name
      -n | --name          : Cluster name
      -m | --managers      : Number of managers (default = 1)
      -w | --workers       : Number of workers (default = 1)
               
               ex : Run 3 masters and 2 workers using the Google project 'foo'
               $(basename $0) -p foo -m 3 -w 2"
EOF
}


# Options parsing
while (($#)); do
    case "$1" in
        -h | --help)   usage;   exit 0;;
        -p | --project) PROJECT=${2}; shift 2;;
        -n | --name) CLUSTER_NAME=${2}; shift 2;;
        -m | --managers) NB_MGERS=${2}; shift 2;;
        -w | --workers) NB_WKERS=${2}; shift 2;;
        *)
            usage
            echo "ERROR : Unknown option"
            exit 3
        ;;
    esac
done

if [ -z ${PROJECT} ]; then
  echo "ERROR: The option -p «gcp account» must be provided"
  usage
  exit 1;
fi
if [ -z ${CLUSTER_NAME} ]; then
  echo "ERROR: The option -n «cluster_name» must be provided"
  usage
  exit 1;
fi
if [ -z ${NB_MGERS} ]; then
  NB_MGERS=1
fi
if [ -z ${NB_WKERS} ]; then
  NB_WKERS=1
fi

# Creates Managers machines
m=1
while [ ${m} -le ${NB_MGERS} ]; do
  docker-machine create -d google --google-project ${PROJECT} ${CLUSTER_NAME}-manager${m}
  declare MANAGER${m}_IP=$(docker-machine ssh ${CLUSTER_NAME}-manager${m} 'ifconfig eth0 | grep "inet addr:" | cut -d: -f2 | cut -d" " -f1')
  export MANAGER${m}_IP
  m=$((m+1))
done
# Creates Workers machines
w=1
while [ ${w} -le ${NB_WKERS} ]; do
  docker-machine create -d google --google-project ${PROJECT} ${CLUSTER_NAME}-worker${w}
  declare WORKER${w}_IP=$(docker-machine ssh ${CLUSTER_NAME}-worker${w} 'ifconfig eth0 | grep "inet addr:" | cut -d: -f2 | cut -d" " -f1')
  export WORKER${w}_IP
  w=$((w+1))
done

# Configures the leader manager and gathers tokens
docker-machine ssh ${CLUSTER_NAME}-manager1 sudo docker swarm init --advertise-addr ${MANAGER1_IP}
WORKER_TOKEN=$(docker-machine ssh ${CLUSTER_NAME}-manager1 sudo docker swarm join-token -q worker)
MANAGER_TOKEN=$(docker-machine ssh ${CLUSTER_NAME}-manager1 sudo docker swarm join-token -q manager)

# Join masters
m=1
if [ ${NB_MGERS} -gt 1 ]; then
  while [ ${m} -le ${NB_MGERS} ]; do
    m=$((m+1))
    docker-machine ssh ${CLUSTER_NAME}-manager${m} sudo docker swarm join --token ${MANAGER_TOKEN} ${MANAGER1_IP}:2377
    m=$((m+1))
  done
fi

# Join workers
w=1
while [ ${w} -le ${NB_WKERS} ]; do
  docker-machine ssh ${CLUSTER_NAME}-worker${w} sudo docker swarm join --token ${WORKER_TOKEN} ${MANAGER1_IP}:2377
  w=$((w+1))
done

eval $(docker-machine env ${CLUSTER_NAME}-manager1)
