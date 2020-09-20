FROM ubuntu:20.04

#setup files needed for compilation
#create userdir and user to run openvas
USER root

RUN  apt-get update && apt-get upgrade -y 

RUN  export DEBIAN_FRONTEND=noninteractive && \
     ln -fs /usr/share/zoneinfo/Europe/Oslo /etc/localtime && \
     apt-get install -y tzdata && \
     dpkg-reconfigure --frontend noninteractive tzdata

RUN  useradd -r -d /opt/gvm -c "GVM User" -s /bin/bash gvm && \
     mkdir /opt/gvm && \
     chown gvm:gvm /opt/gvm && \
     apt-get install rsync sudo gcc g++ make bison flex libksba-dev curl libpcap-dev \
cmake git pkg-config libglib2.0-dev libgpgme-dev nmap libgnutls28-dev uuid-dev \
libssh-gcrypt-dev libldap2-dev gnutls-bin libmicrohttpd-dev libhiredis-dev \
zlib1g-dev libxml2-dev libradcli-dev clang-format libldap2-dev doxygen \
gcc-mingw-w64 xml-twig-tools libical-dev perl-base heimdal-dev libpopt-dev \
libsnmp-dev python3-setuptools python3-paramiko python3-lxml python3-defusedxml \
python3-dev gettext python3-polib xmltoman python3-pip \
texlive-fonts-recommended texlive-latex-extra --no-install-recommends \
postgresql postgresql-contrib postgresql-server-dev-all xsltproc  \
 redis -y && \
     curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
     echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
     apt update 

RUN  echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/opt/gvm/bin:/opt/gvm/sbin:/opt/gvm/.local/bin"' > /etc/environment && \
     echo "/opt/gvm/lib" > /etc/ld.so.conf.d/gvm.conf

RUN  sed '/secure_path=/d' /etc/sudoers && \
     echo 'Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/opt/gvm/sbin"' >> /etc/sudoers && \
     echo "gvm ALL = NOPASSWD: /opt/gvm/sbin/gsad" >> /etc/sudoers.d/gvm && \
     echo "gvm ALL = NOPASSWD: /opt/gvm/sbin/openvas" > /etc/sudoers.d/gvm

USER gvm

RUN  mkdir /tmp/gvm-source && \
     cd /tmp/gvm-source && \
     git clone -b gvm-libs-11.0 https://github.com/greenbone/gvm-libs.git && \
     git clone https://github.com/greenbone/openvas-smb.git && \
     git clone -b openvas-7.0 https://github.com/greenbone/openvas.git && \
     git clone -b ospd-2.0 https://github.com/greenbone/ospd.git && \
     git clone -b ospd-openvas-1.0 https://github.com/greenbone/ospd-openvas.git && \
     git clone -b gvmd-9.0 https://github.com/greenbone/gvmd.git && \
     git clone -b gsa-9.0 https://github.com/greenbone/gsa.git 

ENV  PKG_CONFIG_PATH=/opt/gvm/lib/pkgconfig:$PKG_CONFIG_PATH

RUN  cd /tmp/gvm-source/gvm-libs && \
     mkdir build && \
     cd build && \
     cmake .. -DCMAKE_INSTALL_PREFIX=/opt/gvm && \
     make && \
     make install

USER root

#install gsad spesific dependencies

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install yarn -y

USER gvm
#Build openvas-SMB
RUN export PKG_CONFIG_PATH=/opt/gvm/lib/pkgconfig:$PKG_CONFIG_PATH && \
    cd /tmp/gvm-source/openvas-smb/ && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/opt/gvm && \
    make && \
    make install

#Build openvas scanner

RUN sed -i 's/set (CMAKE_C_FLAGS_DEBUG\s.*\"\${CMAKE_C_FLAGS_DEBUG} \${COVERAGE_FLAGS}\")/set (CMAKE_C_FLAGS_DEBUG \"\${CMAKE_C_FLAGS_DEBUG} -Werror -Wno-error=deprecated-declarations\")/g' /tmp/gvm-source/openvas/CMakeLists.txt && \
    cd /tmp/gvm-source/openvas/ && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/opt/gvm && \
    make && \
    make install 

USER root

RUN ldconfig && \
    echo "db_address = /run/redis-openvas/redis.sock" > /opt/gvm/etc/openvas/openvas.conf && \
    chown gvm:gvm /opt/gvm/etc/openvas/openvas.conf && \
    usermod -aG redis gvm && \
    cp /tmp/gvm-source/openvas/config/redis-openvas.conf /etc/redis/redis.conf && \
    mkdir /run/redis-openvas && \
    chown gvm:redis /etc/redis/redis.conf && \ 
    chown gvm:redis -R /run/redis-openvas && \
    chmod 770 /etc/redis/redis.conf && \
    chmod 770 /run/redis-openvas && \ 
    ls -la /etc/redis/redis.conf && service redis-server start

USER gvm

RUN echo $PKG_CONFIG_PATH && \
    export PKG_CONFIG_PATH=/opt/gvm/lib/pkgconfig:$PKG_CONFIG_PATH && \
    mkdir -p /opt/gvm/lib/python3.8/site-packages/
ENV PYTHONPATH=/opt/gvm/lib/python3.8/site-packages

RUN cd /tmp/gvm-source/ospd && \
    /usr/bin/python3 setup.py install --prefix=/opt/gvm && \
    cd /tmp/gvm-source/ospd-openvas && \
    /usr/bin/python3 setup.py install --prefix=/opt/gvm

RUN  /opt/gvm/bin/greenbone-nvt-sync


RUN cd /tmp/gvm-source/gvmd && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/opt/gvm && \
    make && \
    make install

#Compile gsad
USER gvm

RUN export PKG_CONFIG_PATH=/opt/gvm/lib/pkgconfig:$PKG_CONFIG_PATH && \
    cd /tmp/gvm-source/gsa/ && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/opt/gvm && \
    make && \
    make install

RUN  ls /opt/gvm/sbin/ && \
     /opt/gvm/sbin/greenbone-scapdata-sync && \
     /opt/gvm/sbin/greenbone-certdata-sync 

USER root
RUN ln -s /var/lib/postgresql/postgresql-12-main.log /opt/gvm/var/log/gvm/postgresql.log 
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/opt/gvm/bin:/opt/gvm/sbin:/opt/gvm/.local/bin"

COPY ./start.sh /start.sh
EXPOSE 443:443
    
CMD /start.sh
