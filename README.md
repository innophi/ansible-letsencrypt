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
- `/var/lib/letsencrypt/private/account.key`: it is your Let's Encrypt account key (see below)


This repository provides an Ansible role that install and configure
everything. See [roles/letsencrypt/README.md](roles/letsencrypt/README.md).

After running the Ansible role or installing by hand, see the section 
"How to use scripts" to know how to create and generate certificates.
