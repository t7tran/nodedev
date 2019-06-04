# docker-nodedev

NodeJS development environment

### Steps to use

Go to your project folder and run:

    docker run -u $(id -u):$(id -g) -it --rm -v "$PWD":/code:z --name nodedev -p 4200:4200 -w /code coolersport/nodedev bash

An alias can be created for the above command.
