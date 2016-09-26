#!/bin/bash
set -ex

function ensure_flavor {
    openstack flavor show $1 || openstack --os-region-name=RegionOne \
        flavor create --id $2 --ram $3 --disk $4 --vcpus $5 $1
}

#             name        id ram    disk vcpus
ensure_flavor m1.test     0  128    1    1
ensure_flavor m1.tiny     1  512    1    1
ensure_flavor m1.small    2  2048   20   1
ensure_flavor m1.medium   3  4096   40   2
ensure_flavor m1.large    4  8192   80   4
ensure_flavor m1.xlarge   5  16384  160  8
