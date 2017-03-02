#!/bin/bash -ex

source /etc/apache2/envvars
/usr/sbin/apache2 -DNO_DETACH
