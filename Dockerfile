# modowa-s2i-builder
#FROM openshift/base-centos7
FROM docker.io/centos/php-70-centos7
# TODO: Put the maintainer name in the image metadata
MAINTAINER Jonathan Hill <anfechtung@gmail.com>

# TODO: Rename the builder environment variable to inform users about application you provide them
# ENV BUILDER_VERSION 1.0

# TODO: Set labels used in OpenShift to describe the builder image
LABEL io.k8s.description="Platform for building modowa" \
      io.k8s.display-name="builder modowa" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,modowa"

#Set a bunch of enviornmental variables for reference later
ENV MODOWA_PKG=unix_all.tgz \
    CLIENT_INSTALL=instantclient.tar \
    ORACLE_BASE=/opt/oracle \
    ORACLE_HOME=/opt/oracle/instantclient_12_1 \
    LD_LIBRARY_PATH=/opt/oracle/instantclient_12_1:$LD_LIBRARY_PATH \
    HTTPD_CONF=/etc/apache2/apache2.conf \
    MOD_LOC=/etc/apache2/mods-available \
    APACHE_LOC=/opt/rh/httpd24/root/etc/httpd

USER root
# TODO: Install required packages here:
RUN yum update -y && yum install -y libaio && yum clean all -y

RUN mkdir $ORACLE_BASE

# TODO (optional): Copy the builder files into /opt/app-root
# COPY ./<builder_folder>/ /opt/app-root/

#Copy over the files we need
COPY $MODOWA_PKG $CLIENT_INSTALL $ORACLE_BASE/


#Unzip and build the shit we need
#Setup the instant client
RUN cd $ORACLE_BASE && \
    tar -xzvf $CLIENT_INSTALL && \
    cd $ORACLE_HOME && \
    ln -s libclntsh.so.12.1 libclntsh.so && \
    ln -s libocci.so.12.1 libocci.so && \
    ln -s libclntsh.so.12.1 libclntsh.so.11.1

#build modowa
RUN cd $ORACLE_BASE && \
    tar -xzvf $MODOWA_PKG && \
#    cd modowa/apache24 && \
#    make -kf modowa.mk && \
    cp modowa/apache24/mod_owa.so $APACHE_LOC/modules/ && \
    rm -rf $MODOWA_PKG && \
    rm -rf modowa/

# TODO: Copy the S2I scripts to /usr/libexec/s2i, since openshift/base-centos7 image
# sets io.openshift.s2i.scripts-url label that way, or update that label
COPY ./s2i/bin/ /usr/libexec/s2i

# TODO: Drop the root user and make the content of /opt/app-root owned by user 1001
# RUN chown -R 1001:1001 /opt/app-root

# This default user is created in the openshift/base-centos7 image
USER 1001

# TODO: Set the default port for applications built using this image
EXPOSE 8080

CMD ["usage"]

