#!/usr/bin/env bash

#############
# HealthBot #
#-----------################################
# Ridiculously simple server health alerts #
# https://github.com/gazugafan/healthbot   #
############################################

#HealthBot starts by running all .enabled files in this folder to load general configuration or do any other bootstrapping.
#Next, HealthBot runs all .enabled files in the /checks subfolder to check for health problems--adding any problems it finds to a health_problems array.
#Finally, if any problems are found (and alert throttling isn't in effect), HealthBot will run all .enabled files in the /alerts subfolder to alert you of the problems in various ways.

#Configuration for each check and alert is contained right in their respective file.


#path to configuration folder. this folder should contain general configuration files, along with the "checks" and "alerts" subfolders
configuration_path=/etc/healthbot















#############################
# HACKERS MAY PROCEED BELOW #
#############################

#include general configuration
for f in $configuration_path/*.enabled; do source $f; done

#path to stamp file for alert throttling. should be no reason to change
stamp_file=/tmp/healthbot_stamp

#we'll store all health problems in this array
health_problems=()

#include all checks
for f in $configuration_path/checks/*.enabled; do source $f; done

#used to send all enabled alerts
send_alerts () {
	for f in $configuration_path/alerts/*.enabled; do source $f; done
}

#if there are any problems, we may want to send alerts
problems_count=${#health_problems[@]}
if [ $problems_count -gt 0 ]; then

	#if throttling passes, send alerts
	if [ $throttle_alerts = no ]; then
		send_alerts
	elif [ $throttle_alerts = first ]; then
		if [ ! -f "$stamp_file" ]; then
			touch -d '1 June 2010 12:00' $stamp_file
			send_alerts
		fi
	else		
		[ ! -f $stamp_file ] && touch -d '1 June 2010 12:00' $stamp_file #create stamp file if we haven't yet
		cur_time=$(date +%s)
		stamp_time=$(stat $stamp_file -c %Y)
		time_diff=$(expr $cur_time - $stamp_time)
		if [ $time_diff -gt $throttle_alerts ]; then
			touch $stamp_file
			send_alerts
		fi
	fi
elif [ -f $stamp_file ]; then
	#if problems have cleared, clear the throttle by deleting the stamp file
	rm -f $stamp_file
fi