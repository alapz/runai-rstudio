# Base image
FROM rocker/tidyverse:latest

LABEL maintainer="Vadim Barkhatov <vbarkhatov@cheo.on.ca>"	
LABEL org.opencontainers.image.source=https://github.com/cheori/container-images

#install nginx and some helpful utilities
RUN apt-get update && apt-get install -y nginx gettext-base curl gnupg2 net-tools iputils-ping
RUN rm /etc/nginx/sites-enabled/default


#installsql drivers and R odbc package
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list > /etc/apt/sources.list.d/mssql-release.list

RUN apt-get update &&\
    ACCEPT_EULA=Y apt-get install -y msodbcsql17 

RUN R -e "install.packages('odbc',dependencies=TRUE, repos='http://cran.rstudio.com/')"



#get the sub URLs working using an nginx proxy
COPY nginx.conf /etc/nginx/sites-available/rstudio
COPY nginx_global.conf /etc/nginx/conf.d/

#place nginx launch script in services.d so it can be run by the s6 init like the rstudio service
COPY nginx-run.conf /etc/services.d/nginx/run

# Enable our Nginx site
RUN ln -s /etc/nginx/sites-available/rstudio /etc/nginx/sites-enabled/rstudio


###Permissions Fix###

# the jupyter start script tries to fix the uid/gid by editing the passwd file directly when running as non root, but it can't as it's lacking privileges, so we open it up
RUN chmod 777 /etc/passwd

# pre add the default run.ai group to passwordless sudo so that all users have access to it
RUN groupadd -g 519894939 raiusers
RUN echo "%raiusers ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

#########

COPY rstudio-custom.sh /rstudio-custom.sh
RUN chmod +x /rstudio-custom.sh


CMD ["/rstudio-custom.sh"]

## Andrew Lapointe's extra code
# snap install zotero-snap # trying to install Zotero so we can use BibTex files
