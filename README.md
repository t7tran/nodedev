# docker-nodedev

NodeJS development environment

### Steps to use

Go to your project folder and run:

    docker run -u $(id -u):$(id -g) -it --rm -v "$PWD":"$PWD":z --name nodedev -p 4200:4200 -w "$PWD" t7tran/nodedev bash

Or add the following to your ~/.bash_aliases

	alias nodedev='docker run -u $(id -u):$(id -g) -it --rm -v "$PWD":"$PWD":z --name nodedev -p 4200:4200 -w "$PWD" t7tran/nodedev bash'
