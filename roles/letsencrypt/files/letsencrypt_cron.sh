#!/usr/bin/env bash
# (c) 2017 Innophi
# For the full copyright and license information (MIT), see the LICENSE
# file that was distributed with this source code.

for domain in $(ls /var/lib/letsencrypt/domains/)
do
    /usr/local/bin/letsencrypt_generate.sh $domain
done

