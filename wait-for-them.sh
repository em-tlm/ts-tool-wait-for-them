#!/usr/bin/env bash

# you can use the following to test
# docker run -it -v /tetrascience/ts-devops/docker/scripts:/usr/src/app ubuntu

# WAIT_FOR_THEM_HOSTS=localhost,localhost WAIT_FOR_THEM_PORTS=4000,5000 ./wait-for-them.sh

# WAIT_FOR_THEM_HOSTS=google.com,google.com WAIT_FOR_THEM_PORTS=80,443 ./wait-for-them.sh -- ls -l

# WAIT_FOR_THEM_HOSTS=google.com,google.com,localhost WAIT_FOR_THEM_PORTS=80,443,29009 ./wait-for-them.sh -- ls -l

cmdname=$(basename $0)

echoerr() { if [[ $QUIET -ne 1 ]]; then echo "$@" 1>&2; fi }

usage()
{
    cat << USAGE >&2
Usage:
    $cmdname [host:port]-- command args

    WAIT_FOR_THEM_HOSTS       Host or IP under test
    WAIT_FOR_THEM_PORTS       TCP port under test
                              You need to specify hosts and ports as environmental variables
    host                      Host or IP under test
    port                      TCP port under test
    -- COMMAND ARGS           Execute command with args after the test finishes

    Example:
        "WAIT_FOR_THEM_HOSTS=google.com,google.com WAIT_FOR_THEM_PORTS=80,443 ./wait-for-them.sh -- ls -l"
        "./wait-for-them.sh google.com:80 mongo:27017 postgres:5432 -- ls -l"
        "WAIT_FOR_THEM_HOSTS=google.com,google.com WAIT_FOR_THEM_PORTS=80,443 ./wait-for-them.sh service:80 -- ls -l"
USAGE
    exit 1
}


BASEDIR=$(dirname "$0")

CMD=${CMD:=$BASEDIR/wait-for-it.sh}

# parse the environmental variables
IFS=',' read -ra HOSTS <<< "$WAIT_FOR_THEM_HOSTS"
IFS=',' read -ra PORTS <<< "$WAIT_FOR_THEM_PORTS"


# check the length are the same
len1=${#HOSTS[@]}
len2=${#PORTS[@]}

if [[ $len1 -ne $len2 ]]; then
    echoerr "$cmdname: environmental variables WAIT_FOR_THEM_HOSTS and WAIT_FOR_THEM_PORTS must be equal length"
    exit 1
fi

index=$len1
# get the real stuff to execute
while [[ $# -gt 0 ]]
do
    case "$1" in
        *:* )
        hostport=(${1//:/ })
        HOSTS[$index]=${hostport[0]}
        PORTS[$index]=${hostport[1]}
        shift 1
        let index+=1
        ;;
        --)
        shift
        CLI="$@"
        break
        ;;
        --help)
        usage
        exit 0
        ;;
        *)
        echoerr "$cmdname: Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
done

if [[ $CLI == "" ]]; then
    echoerr "$cmdname: No command arguments passed in"
    usage
    exit 1
fi


i=0
len=${#HOSTS[@]}
echo "$cmdname: waiting for $len dependencies to be up ..."
while [[ $i -lt $len ]]
do
    if [[ $i -eq $len-1 ]]; then
        # use 0 for timeout is intentional
        # we would like to wait till the dependency is up
        $CMD --timeout=0 --host=${HOSTS[i]} --port=${PORTS[i]} -- $CLI
    else
        $CMD --timeout=0 --host=${HOSTS[i]} --port=${PORTS[i]}
    fi
    if [[ $? -ne 0 ]]; then
        exit $?
    fi
    let "i=i+1"
done