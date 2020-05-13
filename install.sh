#!/usr/bin/env bash

function yes_or_no {
    echo "HealthBot: type yes or no and press enter to continue."
}

function require_root {
    # check whether the script runs as root
    if [ "$EUID" -ne 0 ]; then
		echo 'HealthBot: you need to be root to install'
		echo "use 'sudo ./install.sh', 'sudo -s' or run as root user."
		exit 1
    fi
}

function problem {
	echo "[!] ERROR: $1"
	echo "    Aborting installation. No cleanup was done."
	echo "    See log above if you'd like to cleanup manually."
	exit 1
}

function healthbot_install {
    require_root

    echo "[!] Installing HealthBot..."
	
    #download
    echo "[+] Downloading latest version from GitHub..."
	wget --quiet -O healthbot.tar.gz https://codeload.github.com/gazugafan/healthbot/tar.gz/master
	if [ ! $? -eq 0 ] || [ ! -f healthbot.tar.gz ]; then
		problem "Could not download file."
	fi
	
    #extract
    echo "[+] Installing main script at /usr/bin/healthbot..."
	tar -zxf healthbot.tar.gz --strip=2 healthbot-master/src/healthbot.sh
	if [ ! $? -eq 0 ] || [ ! -f healthbot.sh ]; then
		problem "Could not extract main script."
	fi
	
	mv healthbot.sh /usr/bin/healthbot
	if [ ! $? -eq 0 ] || [ ! -f /usr/bin/healthbot ]; then
		problem "Could not move main script to /usr/bin."
	fi
	
    chmod 755 /usr/bin/healthbot
	
    #add etc folder
    echo "[+] Creating configuration at /etc/healthbot..."
	tar -zxf healthbot.tar.gz --strip=3 healthbot-master/src/etc/healthbot
	if [ ! $? -eq 0 ] || [ ! -d healthbot ]; then
		problem "Could not extract configuration files."
	fi

	cp -r healthbot /etc
	if [ ! $? -eq 0 ] || [ ! -d /etc/healthbot ] || [ ! -d /etc/healthbot/checks ] || [ ! -d /etc/healthbot/alerts ]; then
		problem "Could not move configuration to /etc."
	fi
	
	chmod -R 755 /etc/healthbot
	rm -Rf healthbot

    #create cronjob
    echo "[+] Creating hourly cronjob at /etc/cron.d/healthbot..."
	echo -e "#Runs HealthBot to check for server problems and send alerts\n0 * * * * root /usr/bin/healthbot" > /etc/cron.d/healthbot
	if [ ! $? -eq 0 ] || [ ! -f /etc/cron.d/healthbot ]; then
		problem "Could not create cronjob file."
	fi
	
    echo "[+] Cleaning up..."
	rm -f healthbot.tar.gz
	
    echo "[!] HealthBot installed successfully!"
	echo
	echo "    See /etc/healthbot for configuration."
	echo
	echo "    After configuration is complete, you might consider"
	echo "    increasing the frequency of the cronjob schedule."
	echo "    To do this, modify /etc/cron.d/healthbot"
	echo
	echo "    Stay healthy!"
}

function install_check {
    #if already installed, ask the user if they want to reinstall
    if [ -d /etc/healthbot ] || [ -f /usr/bin/healthbot ]; then
        while true
            do
                read -r -p '[?] HealthBot already appears to be installed. Would you like to reinstall? (yes/no): ' REINSTALL
                [ "${REINSTALL}" = "yes" ] || [ "${REINSTALL}" = "no" ] && break
                yes_or_no
            done

        #if no, just exit
        if [ "${REINSTALL}" = "no" ]; then
            exit 0
        fi

        #if yes, reinstall
        if [ "${REINSTALL}" = "yes" ]; then
            echo "[!] HealthBot will be reinstalled now..."
            healthbot_install
        fi
    else
        #not already installed, so install
        healthbot_install
    fi
}

install_check