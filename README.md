# dockerswarm-demo

# Setup the Swarm cluster
- Create vms on GCE
- Initialize the cluster
- Join masters/nodes

```
./setup-cluster.sh
```


# Demo
#### Create an overlay network
```
docker network create --driver overlay --subnet 10.16.0.0/16 ovl1
```

####  Create a routing-mesh service
A tcp port will be opened on each node (similar to kubernetes node port)
```
docker service create --name my-web --network ovl1 --publish 8080:80 --replicas 3 nginx
```

### Rolling update
```
docker service update --image nginx:1.9 my-web
```
