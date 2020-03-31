#!/bin/bash
# -------------------------------------------------------------------------------
# Filename:    docker-run.sh
# Revision:    1.0
# Date:        2020/03/18
# Author:      Glenn Cheng
# Email:       glenn@astralwebinc.com
# Description: 
# Notes:       
# -------------------------------------------------------------------------------

usage()
{
    echo "usage: <docker-run> <local|dev|staging|production> options:<s:|c|d>";
}

commit_hash()
{
    if [ -z "${hash}" ]
        then
            export GIT_COMMIT_HASH=`git rev-parse HEAD`;
        else
            export GIT_COMMIT_HASH=${hash};
    fi
    
    if [ -z "${DOMAINNAME}" ]
        then
            echo '${DOMAINNAME} is null';
        exit ;
    fi
}

unset_env()
{
    unset ENV;
    unset DIRNAME;
    unset DOMAINNAME;
    unset HOSTNAME;
    unset GIT_COMMIT_HASH;
    unset DOCKER_PREFIX;
}

#############################

unset_env;
no_args="true";

if [ "$1" == 'local' ] || [ "$1" == 'dev' ] || [ "$1" == 'staging' ] || [ "$1" == 'production' ]
    then
        no_args="false";
    else
        usage; exit 1;
fi

export ENV=$1;
##inculde env
source ./config/docker-$1-env.sh;

shift;
while getopts "cds:" arg 
do  
    case $arg in
        s)
            if [ ! -z $OPTARG ]
                then
                hash="$OPTARG";
            fi 
            commit_hash
            ;;
        c)
            commit_hash
            ;;
        d)
            DEAMON="-d"
            ;;
        ?)    
            echo "unkonw argument";
            no_args="true";
	        ;;
    esac
done

[[ "$no_args" == "true" ]] && { usage; exit 1; }

if [ -z ${GIT_COMMIT_HASH} ]
    then
        export HOSTNAME=${DOMAINNAME};
    else
        export HOSTNAME=${GIT_COMMIT_HASH}.${DOMAINNAME};
fi

export DIRNAME=`pwd`;
export DOCKER_PREFIX=${GIT_COMMIT_HASH}`basename ${DIRNAME,,}`;

docker-compose config;
echo "---";
echo "";
echo "  # ===============================================================================";
echo "  #containar prefix:    ${DOCKER_PREFIX}";
echo "  #host:                ${HOSTNAME}";
echo "  #database host:       ${DOCKER_PREFIX}.mysql";
echo "  # ===============================================================================";
echo "";

while true; do
    read -p "Please make sure the config, Do you want to run the docker according to the above config? [y/n]    :" yn
    case $yn in
        [Yy]* ) 
            if [ -z "${DOCKER_PREFIX}" ]
                then 
                    docker-compose up ${DEAMON}; echo "command for up:    docker-compose up ${DEAMON}" > info.txt;
                else
                    docker-compose -p ${DOCKER_PREFIX} up ${DEAMON}; echo "command for up:    docker-compose -p ${DOCKER_PREFIX} up ${DEAMON}" > info.txt;
            fi

            echo "command for down:  docker-compose -p ${DOCKER_PREFIX} down" >> info.txt;
            echo "";
            echo "  # ===============================================================================" >> info.txt;
            echo "  #containar prefix: ${DOCKER_PREFIX}" >> info.txt;
            echo "  #host: ${HOSTNAME}" >> info.txt;
            echo "  #database host: ${DOCKER_PREFIX}.mysql" >> info.txt;
            echo "  # ===============================================================================" >> info.txt;

            break;;

        [Nn]* )
            exit;;
        * )
            echo "Please answer yes or no.";;
    esac
done

