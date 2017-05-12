#!/usr/bin/env bash

FILE_SRC=roles/letsencrypt/files

adduser --home /var/lib/letsencrypt --disabled-login letsencrypt

cp $FILE_SRC/letsencrypt.sudoer /etc/sudoers.d/letsencrypt
cp -a $FILE_SRC/*.sh /usr/local/bin/
cp -a $FILE_SRC/acme_tiny.py /usr/local/bin/
cp -a $FILE_SRC/lets-encrypt-x3-cross-signed.pem /var/lib/letsencrypt/letsencrypt_intermediate.pem

mkdir /var/lib/letsencrypt/challenges/ /var/lib/letsencrypt/challenges/ /var/lib/letsencrypt/certs/ /var/lib/letsencrypt/domains/

openssl genrsa 4096 > /var/lib/letsencrypt/private/account.key

chown -r letsencrypt:letsencrypt /var/lib/letsencrypt
chown -r letsencrypt:ssl-cert /var/lib/letsencrypt/private
chmod 640 /var/lib/letsencrypt/private/*

crontab -u letsencrypt - < echo "0 5 * * * /usr/local/bin/letsencrypt_cron.sh"


