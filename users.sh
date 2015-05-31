#!/bin/bash
# Modified from original script by William Blankenship
# Name: listusers.bash
# Purpose: List all normal user and system accounts in the system. Tested on RHEL / Debian Linux
# Author: Vivek Gite <www.cyberciti.biz>, under GPL v2.0+
# Author: William Blankenship <www.cyberciti.biz>
# -----------------------------------------------------------------------------------
_l="/etc/login.defs"
_p="/etc/passwd"

## get mini UID limit ##
l=$(grep "^UID_MIN" $_l)

## get max UID limit ##
l1=$(grep "^UID_MAX" $_l)

## use awk to print if UID >= $MIN and UID <= $MAX and shell is not /sbin/nologin   ##
awk -F':' -v "min=${l##UID_MIN}" -v "max=${l1##UID_MAX}" '{ if ( $3 >= min && $3 <= max  && $7 != "/sbin/nologin" ) print "user:"$0 }' "$_p"



awk -F':' -v "min=${l##UID_MIN}" -v "max=${l1##UID_MAX}" '{ if ( !($3 >= min && $3 <= max  && $7 != "/sbin/nologin")) print "system:"$0 }' "$_p"