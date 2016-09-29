# dockerswarm-demo

# Prequisites

* Google Compute Engine account
* `gcloud` cli configured
* docker >1.12 installed
* docker-machine installed


# Setup the Swarm cluster
The following actions will be done by the script
- Create vms on GCE
- Initialize the cluster
- Join masters/nodes

```
./setup-cluster.sh -p mygcp42 --name clusterfoo --managers 3 --workers 2
```

```
root@manager1:~# docker node ls
ID                           HOSTNAME  STATUS  AVAILABILITY  MANAGER STATUS
3at21jzq19pcnmyjl5sk9izou    worker3   Ready   Active
5uuvvs18isryt4fqz3edhwtyn *  manager1  Ready   Active        Leader
62yguvtdvpohmu51h7j2k0uxu    manager3  Ready   Active        Reachable
bp0alc2yeurjal0eb7h5uu3yv    worker1   Ready   Active
eezk32fq81h74x2vuq59eazr3    worker2   Ready   Active
f21424sy2xd6mll9nbbrnbys4    manager2  Ready   Active        Reachable
```


# Demo
#### Create an overlay network
```
docker network create --driver overlay --subnet 10.16.0.0/16 ovl1
```

####  Create a routing-mesh service
A tcp port will be opened on each node (similar to kubernetes node port)
```
docker service create --name my-web --network ovl1 --publish 8080:80 --replicas 3 nginx:1.10

docker service ps my-web
ID                         NAME      IMAGE       NODE      DESIRED STATE  CURRENT STATE            ERROR
du32qbbzw6jna8n0pp4wrpzxo  my-web.1  nginx:1.10  manager1  Running        Running 5 seconds ago
4vu29q04m7xwbhruop3tkxfdc  my-web.2  nginx:1.10  manager3  Running        Preparing 9 seconds ago
44b3gmbw2pl6vy3a1hzv4rpkp  my-web.3  nginx:1.10  worker1   Running        Preparing 9 seconds ago
```

#### Scale the number of replicas
```
docker service scale my-web=4
my-web scaled to 4

docker service ps my-web 
ID                         NAME      IMAGE       NODE      DESIRED STATE  CURRENT STATE           ERROR
du32qbbzw6jna8n0pp4wrpzxo  my-web.1  nginx:1.10  manager1  Running        Running 2 minutes ago
4vu29q04m7xwbhruop3tkxfdc  my-web.2  nginx:1.10  manager3  Running        Running 2 minutes ago
44b3gmbw2pl6vy3a1hzv4rpkp  my-web.3  nginx:1.10  worker1   Running        Running 2 minutes ago
dbehlelk623cg76mamtduaf5r  my-web.4  nginx:1.10  worker2   Running        Running 33 seconds ago
```

#### Rolling update
```
docker service update --image nginx:1.9 my-web

docker service ps my-web 
ID                         NAME          IMAGE       NODE      DESIRED STATE  CURRENT STATE                    ERROR
du32qbbzw6jna8n0pp4wrpzxo  my-web.1      nginx:1.10  manager1  Running        Running 4 minutes ago
0xpwzfkln38l1hkewl6d76vbi  my-web.2      nginx:1.9   manager2  Running        Running less than a second ago
4vu29q04m7xwbhruop3tkxfdc   \_ my-web.2  nginx:1.10  manager3  Shutdown       Shutdown less than a second ago
2r0dbv7h1xwqase5qrndi48vi  my-web.3      nginx:1.9   worker3   Running        Running 1 seconds ago
44b3gmbw2pl6vy3a1hzv4rpkp   \_ my-web.3  nginx:1.10  worker1   Shutdown       Shutdown 2 seconds ago
4mrhs91dobty7s91tg77huf59  my-web.4      nginx:1.9   worker1   Ready          Assigned less than a second ago
dbehlelk623cg76mamtduaf5r   \_ my-web.4  nginx:1.10  worker2   Shutdown       Running 2 minutes ago
```

### TODO

Try to deploy a complex stack using the "Distributed Application Bundle" format
