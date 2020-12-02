#!/bin/bash

#Starts ssh
/usr/sbin/sshd

#Stars php procceses in the background

/usr/sbin/php-fpm -c /etc/php/fpm

#Stars nginx deamon

nginx -g 'daemon off;'
