This Ansible module allow you to install some scripts to generate letsencrypt
certificates automatically.

It provides some scripts and nginx/apache configuration snippets which avoid to 
stop your server in order to generate the certificates. Only a reloading of the 
server configuration is required.



What is required for this module?
=================================

You should install sudo, python and bash on your linux server, as well as a web server: nginx or apache.


What does this module on your server?
=====================================

- It creates a `letsencrypt` user and a group, and configure him as a sudoer
- It creates some directories and files into `/var/lib/letsencrypt/`. It's where
  all certificates, private keys and other data will be stored, for each domains.
- It copies the [acme_tiny.py](https://github.com/diafygi/acme-tiny), the core of 
  the Let's Encrypt client into `/usr/local/bin/`.
- It copies some bash scripts into `/usr/local/bin/`
- It configure the cron of the `letsencrypt` user
- It copies some snippets into /etc/nginx or /etc/apache2.


Setting up the module
=====================

Copy the roles/letsencrypt/ directory into your roles/ directory.

Create a file, let's say `letsencryptkeys.yml`, into your vars/ directory.

In this file, you will create these variables:

- `letsencrypt_account_key`: it should contain the private key of your letsencrypt account.
- `letsencrypt_certificates`: it contains the list of certificates, private keys and their 
   values. It is optional, as the module installs some scripts to manage them.

Of course, as this file contains sensitive information, it is strongly recommended
to encrypt it with ansible-vault.


In the same file or in an other variables file, you can setup two other variables (optional):

- set `letsencrypt_activate_cron` to `false`, if you don't want to not configure
  a cron script that will check regularly the validity of the certificates
  and regenerates them. If you set it to false, it is then your responsibility
  to launch the script `/usr/local/bin/letsencrypt_generate.sh` regularly.
   
- `letsencrypt_web_server` may content `nginx` or `apache`. It indicates the
  server you used, and so which configuration snippets to install.   

You should then configure your web server and launch for a first time
the `/usr/local/bin/letsencrypt_generate.sh` script, before activating
https virtual hosts.


letsencrypt_account_key variable
--------------------------------

To create the private key of your letsencrypt account, execute on a command line:
`openssl genrsa 4096`. It should output something like:

```
Generating RSA private key, 4096 bit long modulus
.............++
-----BEGIN RSA PRIVATE KEY-----
(...here many lines of random characters...)
-----END RSA PRIVATE KEY-----
```

Copy the content, starting from `-----BEGIN RSA PRIVATE KEY-----`. You should
have this into your `letsencryptkeys.yml` file:

```
letsencrypt_account_key: |
    -----BEGIN RSA PRIVATE KEY-----
    (...here many lines of random characters...)
    -----END RSA PRIVATE KEY-----
```

letsencrypt_certificates variable
---------------------------------

This is a list of certificate variable. It is optional, as the module installs 
some scripts to manage them easily, see the usage documentation.

However, you can fill this variable to register known domains. 

It should be into your `letsencryptkeys.yml` file like this:

```

letsencrypt_certificates:
    -
        name: mydomain.com
        csr: |
            -----BEGIN CERTIFICATE REQUEST-----
            (...here many lines of random characters...)
            -----END CERTIFICATE REQUEST-----
        private_key: |
            -----BEGIN RSA PRIVATE KEY-----
            (...here many lines of random characters...)
            -----END RSA PRIVATE KEY-----
        cert: |
            -----BEGIN CERTIFICATE-----
            (...here many lines of random characters...)
            -----END CERTIFICATE-----
    -
        name: otherdomain.com
        csr: |
            -----BEGIN CERTIFICATE REQUEST-----
            (...here many lines of random characters...)
            -----END CERTIFICATE REQUEST-----
        private_key: |
            -----BEGIN RSA PRIVATE KEY-----
            (...here many lines of random characters...)
            -----END RSA PRIVATE KEY-----
        cert: |
            -----BEGIN CERTIFICATE-----
            (...here many lines of random characters...)
            -----END CERTIFICATE-----
```

- The `name` property indicates the domain name
- The `csr` property contains the CSR (Certificate Signing Request) corresponding to the domain
- The `private_key` property contains the private key used to sign the Let's Encrypt certificate.
  To create the key : `openssl genrsa 4096` (like for `letsencrypt_account_key`, but don't use the same key!)
- The `cert` property contains the let's encrypt certificate. Of course, the first
  time you use the module, you don't have certificates. You can fill this property
  later if you want. Its value can be kept empty however.

To create the CSR, launch one of these command lines, by replacing all `my*` values with your own values:

```
# For a certificate of a single domain
openssl req -new -sha256 -key domain.key -subj "/C=FR/ST=myCountry/L=myTown/O=myCompany/OU=myService/CN=mydomain.com" > domain.csr
    
# For a certificate of multiple domains
openssl req -new -sha256 -key domain.key -subj "/C=FR/ST=myCountry/L=myTown/O=myCompany/OU=myService/CN=mydomain.com" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:mydomain.com,DNS:www.mydomain.com,DNS:other.mydomain.com")) -out domain.csr

# For a wildcard certificate
# it is not supported by Let's Encrypt
```

The command generates a file, `domain.csr`. You can verify it: 
```
    openssl req -text -noout -in domain.csr
```

Copy its content into the `letsencryptkeys.yml` file.

Web server configuration
========================

The module doesn't configure your web server. You have to do it yourself
for each virtual hosts.

In the virtual host that listen on the port 80 (http), you should set an
alias `/.well-known/acme-challenge/` that points to `/var/lib/letsencrypt/challenges/`.

And in the virtual host that listen on the port 443 (https), you should indicate
the ssl certificate that is generated by Let's Encrypt. When you install
Let's encrypt for the first time, you don't have yet certificates, so you must
deactivate virtual hosts that listen on the port 443. You will activate them
after executing `/usr/local/bin/letsencrypt_generate.sh` for a first time.

Nginx configuration
--------------------

To setup the alias `/.well-known/acme-challenge/`, add into your virtual host
configuration:

```
server {
    listen 80;
    ...
    include snippets/letsencrypt_challenge.conf;
    ...
}
```

or without the snippet installed by the ansible module:


```
server {
    listen 80;
    ...
    location /.well-known/acme-challenge/ {
        alias /var/lib/letsencrypt/challenges/;
        try_files $uri =404;
    }
    ...
}
```

Example of a HTTPS virtual host: 

```
server {
    listen 443 ssl;
    server_name mydomain.com, www.mydomain.com;

    ssl_certificate /var/lib/letsencrypt/certs/mydomain.com.pem;
    ssl_certificate_key /var/lib/letsencrypt/private/mydomain.com.key;
    ssl_session_timeout 5m;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA;
    #ssl_session_cache shared:SSL:50m;
    #ssl_dhparam /path/to/server.dhparam;
    ssl_prefer_server_ciphers on;

    ...the rest of your config
}

```

Tip: it is recommended to use the [Mozilla configurator](https://ssl-config.mozilla.org/)
to know how to configure properly ciphers and protocols.


Apache configuration
--------------------

To setup the alias `/.well-known/acme-challenge/`, add into your HTTP virtual host
configuration:

```
<VirtualHost *:80>
    ...
    Include snippets/letsencrypt_challenge.conf
    ...
</VirtualHost>
```


or without the snippet installed by the ansible module:

```
<VirtualHost *:80>
    ...
    Alias /.well-known/acme-challenge/  /var/lib/letsencrypt/challenges/
    <Directory /var/lib/letsencrypt/challenges/>
        Options -Indexes FollowSymLinks
        AllowOverride All
        Order allow,deny
        allow from all
    </Directory>
    ...
</VirtualHost>
```

If you redirect everything from port 80 to http 443, you should
avoid to redirect requests to `/.well-known/acme-challenge/`. A snippet
is provided to configure correctly a redirection.

```
<VirtualHost *:80>
    ...
    Include snippets/letsencrypt_challenge.conf
    Include snippets/letsencrypt_redirect80.conf
    ...
</VirtualHost>
```

Example of a HTTPS virtual host: 

```
<VirtualHost *:443>
    ServerName yoursite.com
    
    SSLEngine on
    SSLCertificateFile /var/lib/letsencrypt/certs/mydomain.com.crt
    SSLCertificateKeyFile /var/lib/letsencrypt/private/mydomain.com.key
    SSLCertificateChainFile /var/lib/letsencrypt/letsencrypt_intermediate.pem
    SSLProtocol All -SSLv2 -SSLv3
    SSLCipherSuite ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA
    SSLHonorCipherOrder     on
</VirtualHost>
```

Tip: it is recommended to use the [Mozilla configurator](https://ssl-config.mozilla.org/)
to know how to configure properly ciphers and protocols.

