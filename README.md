# wait-for-them

`wait-for-them.sh` is based on `wait-for-it.sh` ([github](https://github.com/vishnubob/wait-for-it)).

It is a pure bash script that will wait for the TCP connection to multiple hosts and ports (dependencies)
to be established before running the commands after `--` . 
If any of the expected connections are not 
established, this script will just keep waiting forever. 

For instructions on how to use it, 
the following examples are the best way. 

## Examples

* The following will wait for connection to `google.com:80` and `google.com:443` are established 
 before running `ls -l`. If you have internet, it will succeed right away.
 
  ```bash
  # use environmental variables    
  WAIT_FOR_THEM_HOSTS=google.com,google.com WAIT_FOR_THEM_PORTS=80,443 ./wait-for-them.sh -- ls -l
  
  # use command line arguments
  ./wait-for-them.sh google.com:80 google.com:443 -- ls -l
  ```
* The following will wait for connection to `google.com:80` and `localhost:7777` are established 
 before running `ls -l`. If you do not happen to have port 7777 running on localhost, then 
 the script will just wait here forever, until the `localhost:7777` is available. 
 
  ```bash
  # this will wait for localhost:7777 forever
  WAIT_FOR_THEM_HOSTS=google.com,localhost WAIT_FOR_THEM_PORTS=80,7777 ./wait-for-them.sh -- ls -l
  ```
* You can use this script to have your service/application running in docker to wait for its dependencies. 
  For example, you can add the following to the docker-compose file (make sure the both wait-for-it.sh and 
  wait-for-them.sh are available in the container).
  ```yaml
  coolservice:
    image: node:boron
    working_dir: /usr/src/app
    command: ./wait-for-them.sh redis:6379 postgres:5432 -- pm2 start --no-daemon app.js
    # notice that you can also ask services to depend on each other using "depends_on"
    # but, this does not fully guarantee that the applications running 
    # in the containers will follow the same dependency order. 
    # for example, your coolservice's container
    # will start after rabbitmq container is up, but when coolservice's application starts,
    # the rabbitmq server may still not be ready to receive connections. 
    depends_on:
      - mongo
      - rabbitmq
    environment:
      - WAIT_FOR_THEM_HOSTS=mongo,rabbitmq,funservice
      - WAIT_FOR_THEM_PORTS=27017,5672,80
  ```
## Test
You can test this script by getting into the shell of a docker container in interactive mode.   
  ```bash
  # in local dev environment
  docker run -it -v `pwd`:/usr/src/app -w /usr/src/app ubuntu bash
  
  # in docker container's bash
  WAIT_FOR_THEM_HOSTS=google.com,google.com WAIT_FOR_THEM_PORTS=80,443 ./wait-for-them.sh google.com:80 localhost:7777 -- ls -l
  ```