#!/bin/bash

if [[ -c /dev/kvm ]]; then
    chmod 660 /dev/kvm
    chown root:kvm /dev/kvm
fi

# Mount xenfs for libxl to work
if [[ $(lsmod | grep xenfs) ]]; then
    mount -t xenfs xenfs /proc/xen
fi

if [[ ! -d "/var/log/mcp/libvirt" ]]; then
    mkdir -p /var/log/mcp/libvirt
    touch /var/log/mcp/libvirt/libvirtd.log
    chmod 644 /var/log/mcp/libvirt/libvirtd.log
fi
if [[ $(stat -c %a /var/log/mcp/libvirt) != "755" ]]; then
    chmod 755 /var/log/mcp/libvirt
    chmod 644 /var/log/mcp/libvirt/libvirtd.log
fi
