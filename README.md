# High Availabilty Docker Swarm Config
Using consul, traefik, docker swarm.

## Getting started

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

**Master Node**
```
./consul agent -server -bootstrap -client=0.0.0.0 -bind '{{ GetPrivateInterfaces | include "network" "10.0.0.0/8" | attr "address" }}' -data-dir '/opt/consul'
```
**Clones**
This will also work for master=dockerman1
```
./consul agent -server -bootstrap-expect=1 -client=0.0.0.0 -bind '{{ GetPrivateInterfaces | include "network" "10.0.0.0/8" | attr "address" }}' -data-dir '/opt/consul' --retry-join=dockerman1
```
### Working with Traefik


### Working with docker swarm
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
* **Scale** ```docker service scale haswarm_traefik_init=10```
