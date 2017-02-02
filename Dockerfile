FROM debian:jessie-backports

ENV TERM xterm
ENV DEBIAN_FRONTEND noninteractive
ENV IMSCP_VERSION   1.3.16

RUN apt-get update -y && apt-get dist-upgrade -y && \
    apt-get install -y ca-certificates perl wget whiptail build-essential apt-utils ifupdown libnet-ip-perl && \
    echo 'dictionaries-common dictionaries-common/default-ispell string american (American English)' | debconf-set-selections && \
    echo 'dictionaries-common dictionaries-common/default-wordlist string american (American English)' | debconf-set-selections && \
    cpan Data::Validate::IP

RUN cd /usr/local/src && \
    wget https://github.com/i-MSCP/imscp/archive/${IMSCP_VERSION}.tar.gz && \
    tar -xzf ${IMSCP_VERSION}.tar.gz && mv imscp-${IMSCP_VERSION} imscp

RUN cd /usr/local/src/imscp && \
    head -n -1 docs/preseed.pl > /tmp/preseed.pl && \
    echo "\$main::questions{'SERVER_HOSTNAME'} = 'kaki.sigmapix.com';" >> /tmp/preseed.pl && \
    echo "\$main::questions{'BASE_SERVER_VHOST'} = 'panel.kaki.sigmapix.com';" >> /tmp/preseed.pl && \
    echo "\$main::questions{'DATABASE_USER'} = 'imscp_user';" >> /tmp/preseed.pl && \
    echo "use iMSCP::Net;" >> /tmp/preseed.pl && \
    echo "my \$ips = iMSCP::Net->getInstance();" >> /tmp/preseed.pl && \
    echo "my @serverIps = \$ips->getAddresses();" >> /tmp/preseed.pl && \
    echo "while (\$ips->getAddrVersion(@serverIps[0]) eq 'ipv6') { shift(@serverIps); }" >> /tmp/preseed.pl && \
    echo "\$main::questions{'BASE_SERVER_IP'} = \$serverIps[0];" >> /tmp/preseed.pl && \
    echo "\$main::questions{'BASE_SERVER_PUBLIC_IP'} = \$serverIps[0];" >> /tmp/preseed.pl && \
    echo "print \"Server IP set to: \$serverIps[0]\";" >> /tmp/preseed.pl && \
    echo "" >> /tmp/preseed.pl && \
    echo "1;" >> /tmp/preseed.pl && cat /tmp/preseed.pl && \
    echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections

CMD ["perl","/usr/local/src/imscp/imscp-autoinstall","--debug","--verbose"] #,"--noprompt","--preseed","/tmp/preseed.pl"]
