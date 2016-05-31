#!/bin/bash

if [[ ! -d "/var/log/microservices/nova" ]]; then
    mkdir -p /var/log/microservices/nova
fi
if [[ $(stat -c %a /var/log/microservices/nova) != "755" ]]; then
    chmod 755 /var/log/microservices/nova
fi

source /usr/local/bin/microservices_nova_extend_start
