#!/bin/bash -xe

echo "\$main::questions{'SERVER_HOSTNAME'} = '$(hostname)';" >> /tmp/preseed.pl
echo "\$main::questions{'BASE_SERVER_VHOST'} = '$(hostname)';" >> /tmp/preseed.pl
#echo "\$main::questions{'SQL_SERVER'} = 'remote_server';" >> /tmp/preseed.pl
echo "\$main::questions{'SQL_ROOT_PASSWORD'} = 'password';" >> /tmp/preseed.pl
echo "\$main::questions{'RAINLOOP_SQL_PASSWORD'} = 'password';" >> /tmp/preseed.pl
echo "\$main::questions{'ROUNDCUBE_SQL_PASSWORD'} = 'password';" >> /tmp/preseed.pl
echo "\$main::questions{'FTPD_SQL_PASSWORD'} = 'password';" >> /tmp/preseed.pl
echo "\$main::questions{'DOVECOT_SQL_PASSWORD'} = 'password';" >> /tmp/preseed.pl
echo "\$main::questions{'ADMIN_PASSWORD'} = 'password';" >> /tmp/preseed.pl
echo "\$main::questions{'PHPMYADMIN_SQL_PASSWORD'} = 'password';" >> /tmp/preseed.pl
#echo "use iMSCP::Net;" >> /tmp/preseed.pl
#echo "my \$ips = iMSCP::Net->getInstance();" >> /tmp/preseed.pl
#echo "my @serverIps = \$ips->getAddresses();" >> /tmp/preseed.pl
#echo "while (\$ips->getAddrVersion(@serverIps[0]) eq 'ipv6') { shift(@serverIps); }" >> /tmp/preseed.pl
#echo "\$main::questions{'BASE_SERVER_IP'} = \$serverIps[0];" >> /tmp/preseed.pl
#echo "\$main::questions{'BASE_SERVER_PUBLIC_IP'} = \$serverIps[0];" >> /tmp/preseed.pl
#echo "print \"Server IP set to: \$serverIps[0]\";" >> /tmp/preseed.pl
#echo "\$main::questions{'DATABASE_NAME'} = 'imscp';" >> /tmp/preseed.pl
#echo "\$main::questions{'DATABASE_USER'} = 'root';" >> /tmp/preseed.pl
#echo "\$main::questions{'DATABASE_HOST'} = 'localhost';" >> /tmp/preseed.pl
#echo "\$main::questions{'DATABASE_USER_HOST'} = 'localhost';" >> /tmp/preseed.pl
echo "\$main::questions{'DATABASE_PASSWORD'} = 'password';" >> /tmp/preseed.pl
echo "\$main::questions{'BASE_SERVER_IP'} = '172.18.0.6';" >> /tmp/preseed.pl
echo "\$main::questions{'BASE_SERVER_PUBLIC_IP'} = '172.18.0.6';" >> /tmp/preseed.pl
echo "\$main::questions{'DEFAULT_ADMIN_ADDRESS'} = 'contact@domain.tld';" >> /tmp/preseed.pl
echo "" >> /tmp/preseed.pl
echo "1;" >> /tmp/preseed.pl

cat /tmp/preseed.pl

time perl /usr/local/src/imscp/imscp-autoinstall --debug --verbose --noprompt --preseed /tmp/preseed.pl

/usr/bin/tail -f /dev/null
