# docker-nodedev

NodeJS development environment

### Tag to use

Node LTS version: `lts`
Node Latest/Current version: `current`

### Steps to use

Go to your project folder and run:

	docker run -u $(id -u):$(id -g) -it --rm -v "$PWD":"$PWD":z --name nodedev -p 4200:4200 -w "$PWD" t7tran/nodedev:lts bash

Add docker sock mapping to support docker inside the container: `-v "/var/run/docker.sock:/var/run/docker.sock:rw"`

Or add the following to your ~/.bash_aliases

	alias nodedev='docker run -u $(id -u):$(id -g) -it --rm -v "$PWD":"$PWD":z --name nodedev -p 4200:4200 -w "$PWD" t7tran/nodedev:lts bash'
