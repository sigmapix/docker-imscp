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
    tar -xzf ${IMSCP_VERSION}.tar.gz && mv imscp-${IMSCP_VERSION} imscp && \
    head -n -1 /usr/local/src/imscp/docs/preseed.pl > /tmp/preseed.pl

COPY ./imscp/ /usr/local/src/imscp/
COPY ./entrypoint.sh /entrypoint.sh

EXPOSE 80 443 3306 8880 8443 32800 33800
VOLUME ["/var/www", "/var/mail", "/var/lib/mysql"]
ENTRYPOINT ["/entrypoint.sh"]
