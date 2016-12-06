#!/bin/bash -ex
# Create all necessary (self-signed) certifiactes for libvirt TLS config.
# Based on: https://wiki.libvirt.org/page/TLSDaemonConfiguration
#
# (c) mzawadzki@mirantis.com


echo "* cleaning up old files:"
rm -rf \
    certificate_authority_template.info \
    certificate_authority_key.pem \
    certificate_authority_certificate.pem \
    node_server_template.info \
    node_server_key.pem \
    node_server_certificate.pem \
    node_client_template.info \
    node_client_key.pem \
    node_client_certificate.pem

echo "* checking if necessary tools are installed:"
which certtool || sudo apt-get install -y gnutls-bin

echo "* creating Certificate Authority Template:"
cat >certificate_authority_template.info << EOF
cn = mirantis.com
ca
cert_signing_key
expiration_days = 700
EOF

echo "* creating Certificate Authority Private Key:"
umask 277 && certtool --generate-privkey > certificate_authority_key.pem
ls -la certificate_authority_key.pem

echo "* creating Certificate Authority Certificate file:"
certtool --generate-self-signed \
    --template certificate_authority_template.info \
    --load-privkey certificate_authority_key.pem \
    --outfile certificate_authority_certificate.pem
ls -la certificate_authority_certificate.pem

echo "* creating Server Certificate Template file:"
cat >node_server_template.info <<EOF
organization = mirantis.com
cn = node
tls_www_server
encryption_key
signing_key
EOF

echo "* creating Server Certificate Private Key:"
umask 277 && certtool --generate-privkey > node_server_key.pem
ls -al node_server_key.pem

echo "* creating Server Certificate:"
certtool --generate-certificate \
    --template node_server_template.info \
    --load-privkey node_server_key.pem \
    --load-ca-certificate certificate_authority_certificate.pem \
    --load-ca-privkey certificate_authority_key.pem \
    --outfile node_server_certificate.pem
ls -la node_server_certificate.pem

echo "* creating Client Certificate Template file:"
cat >node_client_template.info <<EOF
organization = mirantis.com
cn = node
encryption_key
tls_www_client
encryption_key
signing_key
EOF

echo "* creating Client Certificate Private Key:"
umask 277 && certtool --generate-privkey > node_client_key.pem
ls -al node_client_key.pem

echo "* creating Client Certificate:"
certtool --generate-certificate \
    --template node_client_template.info \
    --load-privkey node_client_key.pem \
    --load-ca-certificate certificate_authority_certificate.pem \
    --load-ca-privkey certificate_authority_key.pem \
    --outfile node_client_certificate.pem
ls -la node_client_certificate.pem


set +x
echo -e "\n* Generating certificates for libvirtd complete."
ls -al *pem
md5sum *pem
cat << EOF

Here is summary where they should be copied (on each host or container
running libvirtd):

file                                   destination                permissions
-----------------------------------------------------------------------------
certificate_authority_certificate.pem  /etc/pki/CA/cacert.pem             444

node_server_certificate.pem            /etc/pki/libvirt/servercert.pem    440
node_server_key.pem                    /etc/pki/libvirt/private/serverkey.pem
                                                                          440

node_client_certificate.pem            /etc/pki/libvirt/clientcert.pem    400
node_client_key.pem                    /etc/pki/libvirt/private/clientkey.pem
                                                                          400
-----------------------------------------------------------------------------
EOF
