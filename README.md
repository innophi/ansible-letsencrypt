Scripts to manage Let's Encrypt certificates, without the official Let's Encrypt client.

These bash scripts are lightweight, and relies on [acme_tiny](https://github.com/diafygi/acme-tiny).
They avoid to stop the server during a certificate generation, and regenerate
automatically the certificates.

- `letsencrypt_generate.sh`: to verify the validity of a certificate and to regenerate it if needed.
- `letsencrypt_cron.sh`: a cron script that launch `letsencrypt_generate.sh` for each registered domain
- `letsencrypt_preparekeys.sh`: to register a domain, by given its name and the CSR subject.
  It creates the CSR and the private key to sign the certificate.
- `letsencrypt_remove.sh`: to unregister a domain. No more certificate will be
   generated for that domain.

Scripts are here provided inside an Ansible role, but you can install them
by hand. See [roles/letsencrypt/README.md] to use the Ansible role.

