# High Availabilty Docker Swarm Config
Using consul, traefik, docker swarm.

## Getting started

### Working in alpine
```
docker run -dit --name alpine1 alpine ash
docker attach alpine1
apk add openrc
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
```
./consul agent -server -bootstrap-expect=1 -client=0.0.0.0 -bind '{{ GetPrivateInterfaces | include "network" "10.0.0.0/8" | attr "address" }}' -data-dir '/opt/consul' --retry-join=dockerman1
```
