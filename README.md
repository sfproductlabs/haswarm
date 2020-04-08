# High Availabilty Docker Swarm Config
Using consul, traefik, docker swarm. This is recommended for **PUBLIC** swarms only. Setup another swarm for your intranet applications, or at least improve the firewall configuration as per below.

## TL;DR
* Update the [docker-compose.yml](https://github.com/dioptre/haswarm/blob/master/docker-compose.yml) docker swarm/stack to suit your infrastructure.
* Add a label to the machines you want as a load-balancer/traefik ```docker node update --label-add load_balancer=true docker1``` etc.
* Create a unifying network (if you want to make the example usable) Ex. ```docker network create -d overlay webgateway && docker network create -d overlay forenet``` (fore/aft nets are for front/back ends/swarms in our world) and add the machines you want to share to it. You need to add this to the default docker-compose networks if you want to share your network with other stacks.
* Deploy the stack onto your swarm using [deploy.sh](https://github.com/dioptre/haswarm/blob/master/deploy.sh).

### Docker swarm execution options
* Run traefik on only manager nodes (https://docs.traefik.io/providers/docker/#docker-api-access_1) or share the nodes docker socket (https://github.com/Tecnativa/docker-socket-proxy). 
* **OR** use consul to configure the nodes

## Getting started

### Working with ansible
* Run a playbook ```ansible-playbook add-key.yml -i inventory.ini -u root``` where add-key.yml is:
```
# Add my ssh key to hosts
---
  - hosts: all
    tasks:
      - name: Write backup script for each app
        shell: |
          echo 'ssh-rsa Axxxxxxxx.........' >> /root/.ssh/authorized_keys
```
and inventory.ini is a list of hosts:
```
spark1
jupyter1
cassandra1
```
* Run arbitrary command on a server ```ansible jupyter1 -a "cat /etc/hosts"```
* Run command on all servers in ```ansible all .....```
* Run command on ansible group ```ansible docker -a "uptime"``` set the groups in /etc/ansible/hosts:
```
#   - Groups of hosts are delimited by [header] elements
#   - You can enter hostnames or ip addresses
#   - A hostname/ip can be a member of multiple groups

# Ex 1: Ungrouped hosts, specify before any group headers.

[cassandra]
cassandra1
cassandra2
cassandra3

[spark]
cassandra1
cassandra2
cassandra3
spark1
superset1
jupyter1

[docker]
docker1
docker2
```

### Working in alpine
```
docker run -dit --name alpine1 alpine ash
docker attach alpine1
apk add openrc
#could reuse supervisord instead
#apk add supervisor
```

### Working with consul
**Reference:**
* https://www.consul.io/docs/agent/options.html
* https://linuxhint.com/run_consul_server_docker/

**Download**

```wget https://releases.hashicorp.com/consul/1.7.2/consul_1.7.2_linux_amd64.zip```

**Note**
* No more than 5 servers per datacenter
* Get key ```curl http://127.0.0.1:8500/v1/kv/traefik/consul/```
* Put key (no data/null) ```curl --request PUT http://127.0.0.1:8500/v1/kv/traefik/consul/```
* Put key (with data/json) ```curl --request PUT http://127.0.0.1:8500/v1/kv/traefik/consul/watch -H 'Content-Type: application/json' -d 'true'```

**Using Consul to forward proxy traffic**
```
curl --request PUT http://127.0.0.1:8500/v1/kv/traefik/http/routers/radix/rule -d 'Host(`radix.local`)'
curl --request PUT http://127.0.0.1:8500/v1/kv/traefik/http/routers/radix/service -d 'radix'
curl --request PUT http://127.0.0.1:8500/v1/kv/traefik/http/services/radix/loadBalancer/servers/0/url -d 'http://localhost:2012'
```

**Firewall rules/ports for master node**
* ```sudo ufw allow from 10.0.0.0/16 to any port 8500 proto tcp``` 8501 for https
* ```sudo ufw allow from 10.0.0.0/16 to any port 8300 proto tcp```

**Master Node**
```
./consul agent -server -bootstrap -client=0.0.0.0 -ui -bind '{{ GetPrivateInterfaces | include "network" "10.0.0.0/8" | attr "address" }}' -data-dir '/opt/consul'
```
**Clones**
This will also work for master=dockerman1
```
./consul agent -server -bootstrap-expect=1 -client=0.0.0.0 -bind '{{ GetPrivateInterfaces | include "network" "10.0.0.0/8" | attr "address" }}' -data-dir '/opt/consul' --retry-join=dockerman1
```
### Working with Traefik
**Query Matching**
https://docs.traefik.io/routing/routers/#rule

* Ex. ```rule = "Host(`example.com`) || (Host(`example.org`) && Path(`/traefik`))"```

**Download**

```wget https://github.com/containous/traefik/releases/download/v2.2.0/traefik_v2.2.0_linux_amd64.tar.gz```
```wget https://github.com/containous/traefik/releases/download/v1.7.24/traefik_linux-amd64``` for ./traefik17

* [FIRST] Store config into consul (traefik 2.2 doesn't have a command to store config data easily so we need 1.7 https://docs.traefik.io/v1.7/user-guide/kv-config/) ```./traefik17 storeconfig api --docker --docker.swarmMode --docker.domain=mydomain.ca --docker.watch --consul```
* Default run traefik ```/traefik --providers.consul --providers.docker --providers.docker.swarmMode=true --providers.docker.endpoint=unix:///var/run/docker.sock --api.insecure=true --api.dashboard=true```
* Checkout traefik static config http://localhost:8080/api/rawdata


### Working with docker swarm

* Setup ufw firewall (https://github.com/chaifeng/ufw-docker#ufw-docker-util)
* Getting started with swarm (https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/)
* Sharing a port across the swarm  & swarm mode (https://docs.docker.com/engine/swarm/ingress/)
```
docker service create --name dns-cache \
  --publish published=53,target=53 \
  --publish published=53,target=53,protocol=udp \
  dns-cache
```
* Managing secrets (https://docs.docker.com/engine/swarm/secrets/)
* Placement preferences (https://docs.docker.com/engine/swarm/services/)
* Constraining a service to machines - first add a label to the machines ```docker node update --label-add load_balancer=true docker1``` **then** [add to stack/docker-compose.yml](https://www.sweharris.org/post/2017-07-30-docker-placement/):
```
deploy:
      replicas: 2
      placement:
        constraints: [node.labels.load_balancer == true ]
```
* Get the ips for a service ```nslookup tasks.haswarm_alpine.``` and might be useful for other docker-compose stacks to get particpant ips ```dig +short tasks.haswarm_alpine. | grep -v "116.202.183.82" | awk '{system("echo " $1)}'``` (dig is part of dnsutils in debian)

#### Docker secrets
https://docs.docker.com/engine/reference/commandline/secret/

* List secrets ```docker secret ls```
* Create secret from stdin ```echo "SDFDSF" | docker secret create test -```
* Create secret from file ```docker secret create nats-server.key nats-server.key```



#### Docker swarm CLI command primer
* List machines in cluster ```docker node ls```
* Create a network ```docker network create --driver overlay --scope swarm webgateway```
* List stacks ```docker stack ls``` _Note: A stack is actually a docker-compose.yml_
* Deploy a docker-config.yml ```docker stack deploy -c docker-compose.yml haswarm```
* List services ```docker service ls```
* Inspect logs of a container ```docker service logs haswarm_traefik_init -f```
* Update a container definition ```docker service update haswarm_traefik_init --force```
* Examine container processes ```docker service ps haswarm_traefik_init```
* Remove a stack ```docker stack rm haswarm```
* Check container stats ```docker stats haswarm_traefik_init```
* Update a docker container in place ```docker commit ....```
* Enter machine ```docker exec -it 9ac bash```
* Inpsect network ```docker network inspect webgateway```, may want or need to ```sysctl net.ipv4.conf.all.forwarding=1``` (https://docs.docker.com/network/bridge/)
* **Scale** ```docker service scale haswarm_traefik_init=10```
* Save a container to a tar ```docker save -o <path for generated tar file> <image name>```
* Load a container into a docker instance ```docker load -i <path to image tar file>```
* Force a stack group of replicas to reload ```docker service update --force haswarm_traefik```
* Promote a node to a manager (one remains the leader using raft) ```docker node promote docker1``` or ```docker node update docker-1 --role manager```

## TODO
- [ ] Auto update dns if down
- [ ] Auto update floating up if down
- [ ] Check out the ip route in hetzner, binding settings of docker
