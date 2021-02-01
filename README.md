# docker-nodedev

NodeJS development environment

### Steps to use

Go to your project folder and run:

	docker run -u $(id -u):$(id -g) -it --rm -v "$PWD":"$PWD":z --name nodedev -p 4200:4200 -w "$PWD" t7tran/nodedev bash

Add docker sock mapping to support docker inside the container: `-v "/var/run/docker.sock:/var/run/docker.sock:rw"`

Or add the following to your ~/.bash_aliases

	alias nodedev='docker run -u $(id -u):$(id -g) -it --rm -v "$PWD":"$PWD":z --name nodedev -p 4200:4200 -w "$PWD" t7tran/nodedev bash'
