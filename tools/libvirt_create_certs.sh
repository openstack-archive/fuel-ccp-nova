#!/bin/bash -ex
# Create all necessary certifiactes for libvirt TLS config.
# based on: https://wiki.libvirt.org/page/TLSDaemonConfiguration
# (c) mzawadzki@mirantis.com


echo "* cleaning up old files:"
rm -rf \
    certificate_authority_template.info \
    certificate_authority_key.pem \
    certificate_authority_certificate.pem \
    server_template.info \
    server_key.pem \
    server_certificate.pem \
    client_template.info \
    client_key.pem \
    client_certificate.pem \
    fuel-ccp-nova_service_files_defaults.yaml

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
cat >server_template.info <<EOF
organization = mirantis.com
cn = *
tls_www_server
encryption_key
signing_key
EOF

echo "* creating Server Certificate Private Key:"
umask 277 && certtool --generate-privkey > server_key.pem
ls -al server_key.pem

echo "* creating Server Certificate:"
certtool --generate-certificate \
    --template server_template.info \
    --load-privkey server_key.pem \
    --load-ca-certificate certificate_authority_certificate.pem \
    --load-ca-privkey certificate_authority_key.pem \
    --outfile server_certificate.pem
ls -la server_certificate.pem

echo "* creating Client Certificate Template file:"
cat >client_template.info <<EOF
organization = mirantis.com
cn = *
encryption_key
tls_www_client
encryption_key
signing_key
EOF

echo "* creating Client Certificate Private Key:"
umask 277 && certtool --generate-privkey > client_key.pem
ls -al client_key.pem

echo "* creating Client Certificate:"
certtool --generate-certificate \
    --template client_template.info \
    --load-privkey client_key.pem \
    --load-ca-certificate certificate_authority_certificate.pem \
    --load-ca-privkey certificate_authority_key.pem \
    --outfile client_certificate.pem
ls -la client_certificate.pem

echo "* creating related fragment of fuel-ccp-nova/service/files/defaults.yaml:"
YAML_FILE="fuel-ccp-nova_service_files_defaults.yaml"
umask 000
echo -e "    libvirt_certificate_authority_certificate: |\n$(cat certificate_authority_certificate.pem | sed 's/^/        /')" >> ${YAML_FILE}
echo -e "    libvirt_server_certificate: |\n$(cat server_certificate.pem | sed 's/^/        /')" >> ${YAML_FILE}
echo -e "    libvirt_server_key: |\n$(cat server_key.pem | sed 's/^/        /')" >> ${YAML_FILE}
echo -e "    libvirt_client_certificate: |\n$(cat client_certificate.pem | sed 's/^/        /')" >> ${YAML_FILE}
echo -e "    libvirt_client_key: |\n$(cat client_key.pem | sed 's/^/        /')" >> ${YAML_FILE}

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

server_certificate.pem                 /etc/pki/libvirt/servercert.pem    440
server_key.pem                         /etc/pki/libvirt/private/serverkey.pem
                                                                          440

client_certificate.pem                 /etc/pki/libvirt/clientcert.pem    400
client_key.pem                         /etc/pki/libvirt/private/clientkey.pem
                                                                          400
-----------------------------------------------------------------------------

Please check fuel-ccp-nova_service_files_defaults.yaml for copy&paste content
for fuel-ccp-nova/service/files/default.yaml
EOF
