FROM debian:jessie-backports

ENV TERM xterm
ENV DEBIAN_FRONTEND noninteractive
ENV IMSCP_VERSION   1.4.x

RUN apt-get update -y && apt-get dist-upgrade -y && \
    apt-get install -y ca-certificates perl wget whiptail build-essential apt-utils ifupdown libnet-ip-perl && \
    echo 'dictionaries-common dictionaries-common/default-ispell string american (American English)' | debconf-set-selections && \
    echo 'dictionaries-common dictionaries-common/default-wordlist string american (American English)' | debconf-set-selections && \
    echo 'resolvconf resolvconf/linkify-resolvconf boolean false' | debconf-set-selections && \
    cpan Data::Validate::IP

RUN cd /usr/local/src && \
    wget https://github.com/i-MSCP/imscp/archive/${IMSCP_VERSION}.tar.gz && \
    tar -xzf ${IMSCP_VERSION}.tar.gz && mv imscp-${IMSCP_VERSION} imscp_
COPY ./imscp/ /usr/local/src/imscp/
RUN cd /usr/local/src/imscp && \
    head -n -1 docs/preseed.pl > /tmp/preseed.pl && \
    echo "\$main::questions{'SERVER_HOSTNAME'} = '$(hostname)';" >> /tmp/preseed.pl && \
    echo "\$main::questions{'BASE_SERVER_VHOST'} = 'panel.kaki.sigmapix.com';" >> /tmp/preseed.pl && \
#    echo "\$main::questions{'SQL_SERVER'} = 'remote_server';" >> /tmp/preseed.pl && \
    echo "\$main::questions{'SQL_ROOT_PASSWORD'} = 'password';" >> /tmp/preseed.pl && \
    echo "\$main::questions{'RAINLOOP_SQL_PASSWORD'} = 'password';" >> /tmp/preseed.pl && \
    echo "\$main::questions{'ROUNDCUBE_SQL_PASSWORD'} = 'password';" >> /tmp/preseed.pl && \
    echo "\$main::questions{'FTPD_SQL_PASSWORD'} = 'password';" >> /tmp/preseed.pl && \
    echo "\$main::questions{'DOVECOT_SQL_PASSWORD'} = 'password';" >> /tmp/preseed.pl && \
    echo "\$main::questions{'ADMIN_PASSWORD'} = 'password';" >> /tmp/preseed.pl && \
    echo "\$main::questions{'PHPMYADMIN_SQL_PASSWORD'} = 'password';" >> /tmp/preseed.pl && \
#    echo "use iMSCP::Net;" >> /tmp/preseed.pl && \
#    echo "my \$ips = iMSCP::Net->getInstance();" >> /tmp/preseed.pl && \
#    echo "my @serverIps = \$ips->getAddresses();" >> /tmp/preseed.pl && \
#    echo "while (\$ips->getAddrVersion(@serverIps[0]) eq 'ipv6') { shift(@serverIps); }" >> /tmp/preseed.pl && \
#    echo "\$main::questions{'BASE_SERVER_IP'} = \$serverIps[0];" >> /tmp/preseed.pl && \
#    echo "\$main::questions{'BASE_SERVER_PUBLIC_IP'} = \$serverIps[0];" >> /tmp/preseed.pl && \
#    echo "print \"Server IP set to: \$serverIps[0]\";" >> /tmp/preseed.pl && \
#    echo "\$main::questions{'DATABASE_NAME'} = 'imscp';" >> /tmp/preseed.pl && \
#    echo "\$main::questions{'DATABASE_USER'} = 'root';" >> /tmp/preseed.pl && \
#    echo "\$main::questions{'DATABASE_HOST'} = 'localhost';" >> /tmp/preseed.pl && \
#    echo "\$main::questions{'DATABASE_USER_HOST'} = 'localhost';" >> /tmp/preseed.pl && \
    echo "\$main::questions{'DATABASE_PASSWORD'} = 'password';" >> /tmp/preseed.pl && \
    echo "\$main::questions{'BASE_SERVER_IP'} = '172.18.0.6';" >> /tmp/preseed.pl && \
    echo "\$main::questions{'BASE_SERVER_PUBLIC_IP'} = '172.18.0.6';" >> /tmp/preseed.pl && \
    echo "\$main::questions{'DEFAULT_ADMIN_ADDRESS'} = 'alexandre@sigmapix.com';" >> /tmp/preseed.pl && \
    echo "" >> /tmp/preseed.pl && \
    echo "1;" >> /tmp/preseed.pl && cat /tmp/preseed.pl

RUN echo "#!/bin/sh -xe" > /init.sh && \
    echo "perl /usr/local/src/imscp/imscp-autoinstall --debug --verbose --noprompt --preseed /tmp/preseed.pl" >> /init.sh && \
    chmod a+x /init.sh

#RUN perl /usr/local/src/imscp/imscp-autoinstall --debug --verbose --noprompt --preseed /tmp/preseed.pl

EXPOSE 80 443 3306 8880 8443 32800 33800
VOLUME ["/var/www", "/var/mail", "/var/lib/mysql"]
CMD ["/usr/bin/tail", "-f", "/dev/null"]
#CMD ["perl", "/usr/local/src/imscp/imscp-autoinstall","--debug","--verbose","--noprompt","--preseed","/tmp/preseed.pl"]
