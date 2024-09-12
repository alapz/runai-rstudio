#!/bin/bash



config_nginx () {
    # RUNAI_JOB_NAME is provided automatically by run.ai
    if [ -n "$RUNAI_JOB_NAME" ]; then
        export SUBPATH="/$RUNAI_PROJECT/$RUNAI_JOB_NAME"
        # run.ai feeds in the URL of the job into the container we then tell under what subpath nginx should run
        echo "running nginx proxy at $SUBPATH"
        sudo -E sed -i "s|\${SUBPATH}|${SUBPATH}|g" /etc/nginx/sites-available/rstudio
    fi
}


RSTUDIOUSER="rstudio"

if [ "$(id -u)" == 0 ] ; then
    sudo chmod 644 /etc/passwd
    /init
else
    # rename the default rstudio user and add ourserlves as the user with that name
    sed --expression="s/^rstudio:/oidutsr:/" /etc/passwd > /tmp/passwd
    echo "$RSTUDIOUSER:x:$(id -u):$(id -g):,,,:/home/$RSTUDIOUSER:/bin/bash" >> /tmp/passwd
    cat /tmp/passwd > /etc/passwd

    sudo userdel oidutsr
    sudo groupdel rstudio

    config_nginx

    # resetting /etc/passwd permission to default
    sudo chmod 644 /etc/passwd

    #need to make sure this is set as the default home might be /home/runai-home/
    HOME="/home/$RSTUDIOUSER"

    if [[ "${CHOWN_HOME}" == "1" || "${CHOWN_HOME}" == "yes" ]]; then
            sudo chown ${CHOWN_HOME_OPTS} "$(id -u):$(id -g)" $HOME
    fi 

    # expect that the startup script share is mounted
    if [ -f "/share/.startup/.script.sh" ]; then
        source /share/.startup/.script.sh
    else
        echo "File /share/.startup/.script.sh does not exist."
    fi


    # the user's primary gid likely won't have a matching group in the image so we map it
    sudo groupadd -g $(id -g) ${RSTUDIOUSER} || true

    supplementary_gids=$(id -G)

    # add missing groups to /etc/group
    for gid in $supplementary_gids; do
        # check if the GID exists in /etc/group
        if ! getent group "$gid" >/dev/null; then
            # ff it doesn't exist, add it to /etc/group
            group_name="group_$gid"
            echo "Adding group $group_name with GID $gid to /etc/group"
            sudo groupadd -g "$gid" "$group_name"
        fi

        # Add the user to the group
        group_name=$(getent group "$gid" | cut -d: -f1)
        echo "Adding user $username to group $group_name"
        sudo usermod -aG "$group_name" ${RSTUDIOUSER}
    done

    # the envs that get passed to the container get lost when using sudo so we use -E.
    # the bash login process also sets $USER env to root but that is used by the startup to determine the rstudio/default user so we pass it explicitly
    sudo -E USER=$RSTUDIOUSER /init
fi
