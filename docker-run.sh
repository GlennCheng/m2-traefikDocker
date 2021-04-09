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

prefix()
{
    if [ -z "${prefixarg}" ]
        then
            export PREFIX=`git rev-parse HEAD`;
        else
            export PREFIX=${prefixarg};
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
    unset PREFIX;
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
source ./config/docker-env.sh;

shift;
while getopts "cdn:s:" arg 
do  
    case $arg in
        s)
            if [ ! -z $OPTARG ]
                then
                prefixarg="$OPTARG";
            fi 
            prefix
            ;;
        c)
            prefix
            ;;
        d)
            DEAMON="-d";
            ;;
        n)
            if [ ! -z $OPTARG ]
                then
                NEW_INSTALL="true";
                DB_NAME="$OPTARG";
            fi
            ;;    
        ?)    
            echo "unkonw argument";
            no_args="true";
	        ;;
    esac
done

[[ "$no_args" == "true" ]] && { usage; exit 1; }

export DIRNAME=`pwd`;

if [ -z ${PREFIX} ]
    then
        export HOSTNAME=${DOMAINNAME};
        export DOCKER_PREFIX=`basename ${DIRNAME,,}`;
    else
        export HOSTNAME=${PREFIX}.${DOMAINNAME};
        export DOCKER_PREFIX=${PREFIX};
fi

if [ "${NEW_INSTALL}" == "true" ]
    then
        SQL1="GRANT ALL PRIVILEGES ON \\\`${DB_NAME}%\\\` . * TO 'magento'@'%';";
        SQL2="CREATE DATABASE ${DB_NAME};"
        export NEW_DATABASE_COMMAND="mysql -h mysql --user='root' --password='magento' -e \\\"${SQL1}\\\"; mysql -h mysql --user='magento' --password='magento' -e \\\"${SQL2}\\\";";
        export COMPOSER_INSTALL_COMMAND="composer install;";
        export MAGENTO_INSTALL_COMMAND="\
            bin/magento setup:install \
            --db-host=mysql \
            --db-name=${DB_NAME} \
            --db-user=magento \
            --db-password=magento \
            --base-url=http://${HOSTNAME}/ \
            --backend-frontname=admin \
            --admin-firstname=magento \
            --admin-lastname=admin \
            --admin-email=glenn@astralwebinc.com \
            --admin-user=admin \
            --admin-password=admin123 \
            --language=en_US \
            --currency=TWD \
            --timezone='Asia/Taipei' \
            --use-rewrites=1 \
	    --search-engine=elasticsearch7 \
	    --elasticsearch-host=elasticsearch \
	    --elasticsearch-port=9200;";
fi

docker-compose -f docker-compose-$ENV.yml config;
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
                    docker-compose -f docker-compose-$ENV.yml up ${DEAMON}; echo "command for up:    docker-compose -f docker-compose-$ENV.yml up ${DEAMON}" > info.txt;
                else
                    docker-compose -f docker-compose-$ENV.yml -p ${DOCKER_PREFIX} up ${DEAMON}; echo "command for up:    docker-compose -f docker-compose-$ENV.yml -p ${DOCKER_PREFIX} up ${DEAMON}" > info.txt;
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


#install_check();
if [ "${NEW_INSTALL}" == "true" ]
    then
        INTERVAL=0.01
        TT='—>————————
——>———————
———>——————
————>—————
—————>————
——————>———
———————>——
————————>—
—————————>
————————<—
———————<——
——————<———
—————<————
————<—————
———<——————
——<———————
—<————————
<—————————';

        echo -e "\r Installing..."
        #TIME_NOW=`date -u '+%Y-%m-%dT%H:%M:%S.%NZ'`;
        TIME_PAST=${TIME_NOW};
        while [[ $INSTALL_SUCCESS -eq 0 ]]
        do

            for i in $TT
            do
                
                echo -en "\r";
                TIME_NOW=`date -u '+%Y-%m-%dT%H:%M:%S.%NZ'`;
                LOGS=`docker logs -t --since="${TIME_PAST}" --until="${TIME_NOW}" ${DOCKER_PREFIX}_cli_1`;
                docker logs -t --since="${TIME_PAST}" --until="${TIME_NOW}" ${DOCKER_PREFIX}_cli_1
                
                INSTALL_SUCCESS=`echo $LOGS | grep "Magento installation complete." | wc -l`;

                case $INSTALL_SUCCESS in
                    0 )
                        echo -en "\r Installing...[$i]";

                        sleep ${INTERVAL};
                        TIME_PAST=${TIME_NOW};

                        ;;
                    * ) 
                        echo -en "\r Installing...[$i]";

                        echo -e "\n Install finished, restarting docker...";
                        docker-compose -f docker-compose-$ENV.yml -p ${DOCKER_PREFIX} up ${DEAMON}
                        #DONE=true
                        break;
                        ;;
                esac

            done
        done
fi




        

