#!/bin/bash

for arg in "$@"
do
  echo $arg
  if [[ $arg == --NotebookApp.base_url=* ]]; then
    # Remove the prefix, leaving just the URL
    SUBPATH=${arg#*=}
	#if [[ "$SUBPATH" != */ ]]; then
		#export SUBPATH="$SUBPATH/"
	#fi
    echo $SUBPATH

  fi
  
  if [[ $arg == --NotebookApp.token=* ]]; then
    # Remove the prefix and the surrounding quotes, leaving just the token
    token=${arg#*=}
    token=${token//\'/}  
    token=${token//\"/} 
	
	if [[ -z $PASSWORD ]]; then
      PASSWORD=$token
      export PASSWORD
    fi
  fi
done

#NB_UID/GID are env variables that jupyter uses we are just assigning them to the equivalent rocker variables
export USERID=$NB_UID 
export GROUPID=$NB_GID


echo ${SUBPATH}
ls -l /etc/nginx/sites-available/rstudio
grep -F '${SUBPATH}' /etc/nginx/sites-available/rstudio
sed -i "s|\${SUBPATH}|${SUBPATH}|g" /etc/nginx/sites-available/rstudio

cat /etc/nginx/sites-available/rstudio
#/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
/init