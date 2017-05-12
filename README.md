Tiny scripts to manage Let's Encrypt certificates, without the official Let's Encrypt client.


How it works
------------

These bash scripts are lightweight, and relies on [acme_tiny](https://github.com/diafygi/acme-tiny).
They avoid to stop the server during a certificate generation, and regenerate
automatically the certificates.

- `letsencrypt_generate.sh`: to verify the validity of a certificate and to regenerate it if needed.
- `letsencrypt_cron.sh`: a cron script that launch `letsencrypt_generate.sh` for each registered domain
- `letsencrypt_preparekeys.sh`: to register a domain, by given its name and the CSR subject.
   It creates the CSR and the private key to sign the certificate.
- `letsencrypt_remove.sh`: to unregister a domain. No more certificate will be
   generated for that domain.

All data are hosted into a `/var/lib/letsencrypt` directory:

- `/var/lib/letsencrypt/challenges/`: a directory which should be declared in your
   web server virtual hosts, as the alias `/.well-known/acme-challenge/`. See
   examples into [roles/letsencrypt/README.md](roles/letsencrypt/README.md).
- `/var/lib/letsencrypt/domains/`: contains empty files whose names are domain names. 
   It represents the list of domains for which a certificate should be generated and verified. 
- `/var/lib/letsencrypt/private/`: contains private keys of certificates and CSR
- `/var/lib/letsencrypt/certs/`: contains certificates for apache (crt) and nginx (pem)
- `/var/lib/letsencrypt/private/account.key`: is your Let's Encrypt account key (see below)
- `/var/lib/letsencrypt/letsencrypt_intermediate.pem`: is the intermediate 
   certificate of Let's Encrypt (it is provided into `roles/letsencrypt/files/lets-encrypt-x3-cross-signed.pem`)


Scripts are here provided inside an Ansible role, but you can install them
by hand. See [roles/letsencrypt/README.md](roles/letsencrypt/README.md) to use 
the Ansible role and to have examples of Apache/Nginx configurations.

How to install by hand
----------------------

1) Launch `install.sh` as root (or with sudo). (carefull, it is not idempotent).
   It creates a `letsencrypt` user, 
   directories into `/var/lib/letsencrypt`, and a Let's Encrypt account key into 
  `/var/lib/letsencrypt/private/account.key`. It also install all scripts
  and configure a cron script for the letsencrypt user.

2) configure your virtual hosts (on port 80) to declare `/.well-known/acme-challenge/`
  aliases. See `roles/letsencrypt/files/snippet_*` and examples into 
  [roles/letsencrypt/README.md](roles/letsencrypt/README.md).

3) you are now ready to create files needed to generate certificates


How to use scripts
--------------------

To create a certificate, first create files needed to generate it, with 
`letsencrypt_preparekeys.sh` (to run as letsencrypt user):

```bash
letsencrypt_preparekeys.sh <domain> <csr subject> [<otherdomain>]*
```

Example:

```bash
# for a certificate for a single domain
letsencrypt_preparekeys.sh my.domain.com "/C=FR/ST=France/L=MyTown/O=MyCompany/OU=MyService"

# for a certificate with multiple domains
letsencrypt_preparekeys.sh my.domain.com "/C=FR/ST=France/L=MyTown/O=MyCompany/OU=MyService" domain.com other.domain.com 
```

You need to launch `letsencrypt_preparekeys.sh` only a single time.

You can then generate the certificate:

```bash
letsencrypt_generate.sh my.domain.com
```

Then you can setup a virtual host on the port 443 in your Apache/Nginx configuration.

You can run `letsencrypt_generate.sh my.domain.com` as many times you want,
but it will regenerate the certificate only if there is less than 15 days before
the end of life of the certificate.

If you want to force the regeneration, just remove the certificate
`rm /var/lib/letsencrypt/certs/my.domain.com.*`, before launching `letsencrypt_generate.sh`.

To delete a certificate and its private key and CSR,  launch `letsencrypt_remove.sh my.domain.com`
(you must remove the virtual host configuration before to execute this script).

To deactivate the generation of a certificate, launch `letsencrypt_remove.sh --deactivate my.domain.com`.
