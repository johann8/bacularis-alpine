#!/bin/bash
# for debug
# set -x

### ==================  Bacula run script: BEFORE/AFTER ===============

#
### === set variables ===
#
# Output to console, logfile, and docker log stdout. # fd/1 for stdout
LOGFILE=/var/log/docker_backup.log # /config is the location within Bacula docker _data directory
SYSTEMCTL_COMMAND=`command -v systemctl`; echo ${SYSTEMCTL_COMMAND}

# Array - exclude bacula container
AR_EXCLUDE_B_CONTAINER=(bacularis bacula-db bacula-smtpd)

# EXCLUDE_BACULA_CONTAINER=$(docker ps --format "{{.ID}} {{.Names}}" |grep Bacula | awk '{print $}')
#echo ${AR_EXCLUDE_B_CONTAINER[@]}
#for B_CONTAINER in ${AR_EXCLUDE_B_CONTAINER[*]}; do
#    echo "Bacula Docker Container: ${B_CONTAINER}"
#done
#echo ${AR_EXCLUDE_B_CONTAINER[0]}
#echo ${AR_EXCLUDE_B_CONTAINER[1]}
#echo ${AR_EXCLUDE_B_CONTAINER[2]}

#
### === Main Script ===
#
SCRIPT_PARAM="Run script ${1}"
SEPARATOR_LENGTH=$(( ${#SCRIPT_PARAM} + 1 ))
SEPARATOR=$(printf '=%.0s' $(seq 1 ${SEPARATOR_LENGTH}))
printf "\n" | tee /proc/1/fd/1 -a ${LOGFILE}
printf "${SEPARATOR}\n" | tee /proc/1/fd/1 -a ${LOGFILE}
printf "${SCRIPT_PARAM}\n" | tee /proc/1/fd/1 -a ${LOGFILE}
printf "${SEPARATOR}\n" | tee /proc/1/fd/1 -a ${LOGFILE}
printf "Script start: $(date)\n" | tee /proc/1/fd/1 -a ${LOGFILE}

# check if service monit is available.
if [[ -x /usr/local/bin/monit ]]; then
    printf "Monit service is available.\n" | tee /proc/1/fd/1 -a ${LOGFILE}
    S_MONIT=1
else
    printf "Monit service is not available.\n" | tee /proc/1/fd/1 -a ${LOGFILE}
    S_MONIT=0
fi

# Check if command (file) NOT exist OR IS empty.
if [ ! -s "${SYSTEMCTL_COMMAND}" ]; then
    printf "Command \"${SYSTEMCTL_COMMAND}\" is not available.\n" | tee /proc/1/fd/1 -a ${LOGFILE}
else
    printf "Command \"${SYSTEMCTL_COMMAND}\" is available.\n" | tee /proc/1/fd/1 -a ${LOGFILE}
fi

# run main script
if [ ${1} == "BEFORE" ] || [ ${1} == "before" ]; then
    printf "Bacula running script BEFORE...\n" | tee /proc/1/fd/1 -a ${LOGFILE}
    printf "Found $(docker ps -aq | wc -l) Docker containers.\n" | tee /proc/1/fd/1 -a ${LOGFILE}
    CONTAINERS=$(docker ps -aq)
    TOTAL_CONTAINERS=$(echo "$CONTAINERS" | wc -w)
    CONTAINER_COUNTER=0
    printf ".....................................................\n" | tee /proc/1/fd/1 -a ${LOGFILE}

    # Stop monit service
    if [ ${S_MONIT} == 1 ]; then
        printf "Stopping monit service...\n" | tee /proc/1/fd/1 -a ${LOGFILE}
        ${SYSTEMCTL_COMMAND} stop monit

        if [ $? == 0 ]; then
            printf "Monit service was successfully stopped.\n" | tee /proc/1/fd/1 -a ${LOGFILE}
        else
            printf "Monit serveice could not be stopped.\n" | tee /proc/1/fd/1 -a ${LOGFILE}
        fi
    fi

    if [ -n "$CONTAINERS" ]; then
        for container in $CONTAINERS; do
            CONTAINER_COUNTER=$((CONTAINER_COUNTER+1))
            CONTAINER_NAME=$(docker inspect --format '{{.Name}}' $container | sed 's/^\///')

            # skip container"bacula-smtpd bacularis bacula-db"
            if [[ ${CONTAINER_NAME} =  ${AR_EXCLUDE_B_CONTAINER[0]} ]] || [[ ${CONTAINER_NAME} = ${AR_EXCLUDE_B_CONTAINER[1]} ]] || [[ ${CONTAINER_NAME} = ${AR_EXCLUDE_B_CONTAINER[2]} ]]; then
                printf "Container \"${CONTAINER_NAME}\" will be skipped..." | tee /proc/1/fd/1 -a ${LOGFILE}
                printf "\n" | tee /proc/1/fd/1 -a ${LOGFILE}
            else
                printf "\n Stopping container ($CONTAINER_COUNTER/$TOTAL_CONTAINERS): ${CONTAINER_NAME} ($container)...\n" | tee /proc/1/fd/1 -a ${LOGFILE}
                docker stop $container > /dev/null 2>&1

                DOCSTATE=$(docker inspect -f {{.State.Running}} $container)
                printf "   Container running state: ${DOCSTATE}\n" | tee /proc/1/fd/1 -a ${LOGFILE}

                if [ "${DOCSTATE}" == "false" ]; then
                    printf "*** Container stopped.\n" | tee /proc/1/fd/1 -a ${LOGFILE}
                else
                    printf "Container ${CONTAINER_NAME} ($container) still not running, should be started!!!\n" | tee /proc/1/fd/1 -a ${LOGFILE}
                fi
            fi
            printf ".....................................................\n" | tee /proc/1/fd/1 -a ${LOGFILE}
        done
    else
        printf "No Docker containers found.\n" | tee /proc/1/fd/1 -a ${LOGFILE}
    fi
elif [ ${1} == "AFTER" ] || [ ${1} == "after" ]; then
    printf "Bacula running script AFTER...\n" | tee /proc/1/fd/1 -a ${LOGFILE}

    printf "Found $(docker ps -aq | wc -l) Docker containers.\n" | tee /proc/1/fd/1 -a ${LOGFILE}
    printf ".....................................................\n" | tee /proc/1/fd/1 -a ${LOGFILE}
    CONTAINERS=$(docker ps -aq)
    TOTAL_CONTAINERS=$(echo "$CONTAINERS" | wc -w)
    CONTAINER_COUNTER=0

    if [ -n "$CONTAINERS" ]; then
        for container in $CONTAINERS; do
            CONTAINER_COUNTER=$((CONTAINER_COUNTER+1))
            CONTAINER_NAME=$(docker inspect --format '{{.Name}}' $container | sed 's/^\///')

            # skip container Bacula
            if [[ ${CONTAINER_NAME} =  ${AR_EXCLUDE_B_CONTAINER[0]} ]] || [[ ${CONTAINER_NAME} = ${AR_EXCLUDE_B_CONTAINER[1]} ]] || [[ ${CONTAINER_NAME} = ${AR_EXCLUDE_B_CONTAINER[2]} ]]; then
                printf "Container \"${CONTAINER_NAME}\" will be skipped..." | tee /proc/1/fd/1 -a ${LOGFILE}
                printf "\n" | tee /proc/1/fd/1 -a ${LOGFILE}
            else
                printf " Starting container ($CONTAINER_COUNTER/$TOTAL_CONTAINERS): ${CONTAINER_NAME} ($container)...\n" | tee /proc/1/fd/1 -a ${LOGFILE}
                docker start $container > /dev/null 2>&1

                DOCSTATE=$(docker inspect -f {{.State.Running}} $container)
                printf "   Container running state: ${DOCSTATE}\n" | tee /proc/1/fd/1 -a ${LOGFILE}

                if [ "${DOCSTATE}" == "true" ]; then
                    printf "*** Container started.\n" | tee /proc/1/fd/1 -a ${LOGFILE}
                else
                    printf "Container ${CONTAINER_NAME} ($container) still not running, should be started!!!\n" | tee /proc/1/fd/1 -a ${LOGFILE}
                fi
            fi
            printf ".....................................................\n" | tee /proc/1/fd/1 -a ${LOGFILE}
        done

        # Start monit service
        if [ ${S_MONIT} == 1 ]; then
            printf "Starting monit service...\n" | tee /proc/1/fd/1 -a ${LOGFILE}
            ${SYSTEMCTL_COMMAND} start monit

            if [ $? == 0 ]; then
                printf "Monit service was successfully started.\n" | tee /proc/1/fd/1 -a ${LOGFILE}
            else
                printf "Monit serveice could not be started.\n" | tee /proc/1/fd/1 -a ${LOGFILE}
            fi
        fi
    else
        printf "No Docker containers found.\n" | tee /proc/1/fd/1 -a ${LOGFILE}
    fi
else
    printf "ERROR: No matching variable was passed.\n" | tee /proc/1/fd/1 -a ${LOGFILE}
fi

printf "Script stopped: $(date)\n" | tee /proc/1/fd/1 -a ${LOGFILE}
printf "${SEPARATOR}\n" | tee /proc/1/fd/1 -a ${LOGFILE}

