#!/bin/bash
{
	#------------------------------------------------------------------------------------------------
	# Setup a Debian installation, for DietPi.
	# - PRE-REQ
	#	System currently running a Debian image (ideally minimal)
	#	System with active eth0 connection
	#	No USB drives attached
	#------------------------------------------------------------------------------------------------
	# DO NOT USE. Currently under testing.
	#------------------------------------------------------------------------------------------------
	#Force en_GB Locale for whole script. Prevents incorrect parsing with non-english locales.
	LANG=en_GB.UTF-8

	#Ensure we are in users home dir: https://github.com/Fourdee/DietPi/issues/905#issuecomment-298223705
	cd "$HOME"

	#Exit path for non-root logins.
	if (( $UID != 0 )); then

		echo -e 'Error: Root privileges required. Please run the command with "sudo"\n'
		exit

	fi

	#------------------------------------------------------------------------------------------------
	#Globals
	#------------------------------------------------------------------------------------------------
	#System
	DISTRO=4
	DISTRO_NAME='stretch'
	HW_MODEL=0
	HW_ARCH_DESCRIPTION=$(uname -m)
	if [ "$HW_ARCH_DESCRIPTION" = "armv6l" ]; then

		HW_ARCH=1

	elif [ "$HW_ARCH_DESCRIPTION" = "armv7l" ]; then

		HW_ARCH=2

	elif [ "$HW_ARCH_DESCRIPTION" = "aarch64" ]; then

		HW_ARCH=3

	elif [ "$HW_ARCH_DESCRIPTION" = "x86_64" ]; then

		HW_ARCH=10

	else

		echo -e "Unknown HW_ARCH $HW_ARCH_DESCRIPTION, aborting"
		exit

	fi

	#Funcs
	INTERNET_ADDRESS=''
	Check_Connection(){

		wget -q --spider --timeout=10 --tries=2 "$INTERNET_ADDRESS"

	}

	#DietPi-Notify:
	dietpi-notify(){

		local ainput_string=("$@")

		local status_text_ok="\e[32mOk\e[0m"
		local status_text_failed="\e[31mFailed:\e[0m"

		local bracket_string_l="\e[90m[\e[0m"
		local bracket_string_r="\e[90m]\e[0m"

		#Funcs

		Print_Ok(){

			echo -ne " $bracket_string_l\e[32mOk\e[0m$bracket_string_r"

		}

		Print_Failed(){

			echo -ne " $bracket_string_l\e[31mFailed\e[0m$bracket_string_r"

		}

		# - Print all input string on same line
		# - $1 = start printing from word number $1
		Print_Input_String(){

			for (( i=$1;i<${#ainput_string[@]} ;i++))
			do
				echo -ne " ${ainput_string[${i}]}"
			done

			echo -e ""

		}

		# Main Loop
		#--------------------------------------------------------------------------------------
		echo -e ""

		if (( $1 == -1 )); then

			if [ "$2" = "0" ]; then

				ainput_string+=("Completed")
				Print_Ok
				Print_Input_String 2
				echo -e ""

			else

				ainput_string+=("An issue has occured")
				Print_Failed
				Print_Input_String 2
				echo -e ""

			fi

		#--------------------------------------------------------------------------------------
		#Status Ok
		#$@ = txt desc
		elif (( $1 == 0 )); then

			Print_Ok
			Print_Input_String 1

		#Status failed
		#$@ = txt desc
		elif (( $1 == 1 )); then

			Print_Failed
			Print_Input_String 1

		#Status Info
		#$@ = txt desc
		elif (( $1 == 2 )); then

			echo -ne " $bracket_string_l\e[0mInfo\e[0m$bracket_string_r"
			echo -ne "\e[90m"
			Print_Input_String 1
			echo -ne "\e[0m"

		fi

		echo -e ""
		#-----------------------------------------------------------------------------------
		unset ainput_string
		#-----------------------------------------------------------------------------------
	}

	Error_Check(){

		#Grab exit code in case of failure
		exit_code=$?
		if (( $exit_code != 0 )); then

			dietpi-notify 1 "($exit_code): Script aborted"
			exit $exit_code

		else

			dietpi-notify 2 "($exit_code): Passed"
		fi

	}

	#Apt-get
	AGI(){

		local string="$@"

		local force_WHIP_OPTIONs='--force-yes'

		if (( $DISTRO >= 4 )); then

			force_WHIP_OPTIONs='--allow-downgrades --allow-remove-essential --allow-change-held-packages --allow-unauthenticated'

		fi

		DEBIAN_FRONTEND=noninteractive $(which apt) install -y $force_WHIP_OPTIONs $string

	}

	#Whiptail
	WHIP_BACKTITLE='DietPi-Prep'
	WHIP_TITLE=0
	WHIP_DESC=0
	WHIP_MENU_ARRAY=0
	WHIP_RETURN_VALUE=0
	WHIP_DEFAULT_ITEM=0
	WHIP_OPTION=0
	WHIP_CHOICE=0
	Run_Whiptail(){

		WHIP_OPTION=$(whiptail --title "$WHIP_TITLE" --menu "$WHIP_DESC" --default-item "$WHIP_DEFAULT_ITEM" --backtitle "$WHIP_BACKTITLE" 20 80 12 "${WHIP_MENU_ARRAY[@]}" 3>&1 1>&2 2>&3)
		WHIP_CHOICE=$?
		if (( $WHIP_CHOICE == 0 )); then

			WHIP_RETURN_VALUE=$WHIP_OPTION

		else

			dietpi-notify 1 'No choices detected, aborting'
			exit 0

		fi

		#delete []
		unset WHIP_MENU_ARRAY

	}

	#------------------------------------------------------------------------------------------------
	#------------------------------------------------------------------------------------------------
	#------------------------------------------------------------------------------------------------
	# MAIN LOOP
	#------------------------------------------------------------------------------------------------
	#------------------------------------------------------------------------------------------------
	#------------------------------------------------------------------------------------------------

	#------------------------------------------------------------------------------------------------
	dietpi-notify 0 'Step 1: Initial prep to allow this script to function:'
	#------------------------------------------------------------------------------------------------
	dietpi-notify 2 'Updating APT:'

	apt-get clean
	Error_Check

	apt-get update
	Error_Check

	dietpi-notify 2 'Installing core packages, required for this script to function:'

	AGI wget unzip whiptail
	Error_Check

	#------------------------------------------------------------------------------------------------
	dietpi-notify 0 'Step 2: Hardware selection:'
	#------------------------------------------------------------------------------------------------

	WHIP_TITLE='Hardware selection:'
	WHIP_DESC='Please select the current device this is being installed on:'
	WHIP_DEFAULT_ITEM=0
	WHIP_MENU_ARRAY=(

		'110' 'RoseapplePi'
		'100' 'Asus Tinker Board'
		'90' 'A20-OLinuXino-MICRO'
		'80' 'Cubieboard 3'
		'71' 'Beagle Bone Black'
		'70' 'Sparky SBC'
		'66' 'NanoPi M1 Plus'
		'65' 'NanoPi NEO 2'
		'64' 'NanoPi NEO Air'
		'63' 'NanoPi M1/T1'
		'62' 'NanoPi M3/T3'
		'61' 'NanoPi M2/T2'
		'60' 'NanoPi Neo'
		'51' 'BananaPi Pro (Lemaker)'
		'50' 'BananaPi M2+ (sinovoip)'
		'43' 'Rock64'
		'42' 'Pine A64+ (2048mb)'
		'41' 'Pine A64+ (1024mb)'
		'40' 'Pine A64  (512mb)'
		'38' 'OrangePi PC 2'
		'37' 'OrangePi Prime'
		'36' 'OrangePi Win'
		'35' 'OrangePi Zero Plus 2 (H3/H5)'
		'34' 'OrangePi Plus'
		'33' 'OrangePi Lite'
		'32' 'OrangePi Zero (H2+)'
		'31' 'OrangePi One'
		'30' 'OrangePi PC'
		'21' 'x86_64 Native PC'
		'20' 'x86_64 VMware/VirtualBox'
		'13' 'oDroid U3'
		'12' 'oDroid C2'
		'11' 'oDroid XU3/4'
		'10' 'oDroid C1'
		'3' 'Raspberry Pi 3'
		'2' 'Raspberry Pi 2'
		'1' 'Raspberry Pi 1/Zero (512mb)'
		'0' 'Raspberry Pi 1 (256mb)'

	)

	Run_Whiptail
	HW_MODEL=$WHIP_RETURN_VALUE

	dietpi-notify 2 "Setting HW_MODEL index of: $HW_MODEL"
	dietpi-notify 2 "CPU ARCH = $HW_ARCH : $HW_ARCH_DESCRIPTION"

	#------------------------------------------------------------------------------------------------
	dietpi-notify 0 'Step 3: Distro selection / APT prep:'
	#------------------------------------------------------------------------------------------------

	WHIP_TITLE='Distro Selection:'
	WHIP_DESC='Please select a distro to install on this system. Selecting a distro that is older than the current installed on system, is not supported.'
	WHIP_DEFAULT_ITEM=4
	WHIP_MENU_ARRAY=('4' 'stretch (recommended)')
	if (( $HW_MODEL >= 10 )); then

		WHIP_MENU_ARRAY+=('5' 'buster (testing only, not officially suppoted)')

	fi

	Run_Whiptail
	DISTRO=$WHIP_RETURN_VALUE

	if (( $DISTRO == 3 )); then

		DISTRO_NAME='jessie'

	elif (( $DISTRO == 4 )); then

		DISTRO_NAME='stretch'

	elif (( $DISTRO == 5 )); then

		DISTRO_NAME='buster'

	fi

	dietpi-notify 2 'Removing conflicting apt sources.list.d'

	#rm /etc/apt/sources.list.d/* &> /dev/null #Probably a bad idea
	rm /etc/apt/sources.list.d/deb-multimedia.list &> /dev/null #meveric


	dietpi-notify 2 "Setting APT sources.list: $DISTRO_NAME $DISTRO"

	if (( $HW_MODEL < 10 )); then

		cat << _EOF_ > /etc/apt/sources.list
deb https://www.mirrorservice.org/sites/archive.raspbian.org/raspbian $DISTRO_NAME main contrib non-free rpi
_EOF_

		cat << _EOF_ > /etc/apt/sources.list.d/raspi.list
deb https://archive.raspberrypi.org/debian/ $DISTRO_NAME main ui
_EOF_

	else

		cat << _EOF_ > /etc/apt/sources.list
deb http://ftp.debian.org/debian/ $DISTRO_NAME main contrib non-free
deb http://ftp.debian.org/debian/ $DISTRO_NAME-updates main contrib non-free
deb http://security.debian.org $DISTRO_NAME/updates main contrib non-free
deb http://ftp.debian.org/debian/ $DISTRO_NAME-backports main contrib non-free
_EOF_

	fi
	Error_Check

	#	Buster, remove backports: https://github.com/Fourdee/DietPi/issues/1285#issuecomment-351830101
	if (( $DISTRO == 5 )); then

		sed -i '/backports/d' /etc/apt/sources.list

	fi

	#NB: Apt mirror will get overwritten by: /DietPi/dietpi/func/dietpi-set_software apt-mirror default : during finalize.

	# - @MichaIng https://github.com/Fourdee/DietPi/pull/1266/files
	dietpi-notify 2 "Marking all packages as auto installed first, to allow allow effective autoremove afterwards"

	apt-mark auto $(apt-mark showmanual)
	Error_Check

	# - @MichaIng https://github.com/Fourdee/DietPi/pull/1266/files
	dietpi-notify 2 "Temporary disable automatic recommends/suggests installation and allow them to be autoremoved:"

	cat << _EOF_ > /etc/apt/apt.conf.d/99norecommends
APT::Install-Recommends "false";
APT::Install-Suggests "false";
APT::AutoRemove::RecommendsImportant "false";
APT::AutoRemove::SuggestsImportant "false";
_EOF_
	Error_Check

	dietpi-notify 2 "Forcing use of existing apt configs if available"

	cat << _EOF_ > /etc/apt/apt.conf.d/local
Dpkg::options {
   "--force-confdef";
   "--force-confold";
}
_EOF_
	Error_Check

	dietpi-notify 2 "Updating APT for $DISTRO_NAME:"

	apt-get clean
	Error_Check

	apt-get update
	Error_Check


	#------------------------------------------------------------------------------------------------
	dietpi-notify 0 'Step 4: APT removals:'
	#------------------------------------------------------------------------------------------------

	# - DietPi list of minimal required packages which must be installed:
	#	dpkg --get-selections | awk '{print $1}' | sed 's/:armhf//g' | sed "s/^/'/g" | sed "s/$/'/g"
	aPACKAGES_REQUIRED_INSTALL=(

		'adduser'
		'apt'
		'apt-transport-https'
		'apt-utils'
		'base-files'
		'bash'
		'bash-completion'
		'bc'
		'bsdutils'
		'bzip2'
		'ca-certificates'
		'console-setup'
		'cpio'
		'crda'
		'cron'
		'curl'
		'dbus'
		'debconf'
		'debianutils'
		'dosfstools' 		# DietPi-Drive_Manager
		'dphys-swapfile'
		'dpkg'
		'ethtool'
		'fake-hwclock'
		'fbset'
		'firmware-atheros'
		'firmware-brcm80211'
		'firmware-ralink'
		'firmware-realtek'
		'fuse'
		'gpgv'
		'grep'
		'gzip'
		'hdparm'
		'hfsplus'
		'hostname'
		'htop'
		'ifupdown'
		'initramfs-tools'
		'iputils-ping'
		'isc-dhcp-client'
		'iw'
		'locales'
		'mawk'
		'nano'
		'net-tools'
		'ntfs-3g'
		'ntp'
		'p7zip-full'
		'parted'
		'passwd'
		'procps'
		'psmisc'
		'resolvconf'
		'rfkill' 			#Used by some onboard WiFi chipsets
		'sed'
		'sensible-utils'
		'startpar'
		'sudo'
		'systemd'
		'systemd-sysv'
		'tar'
		'tzdata'
		'udev'
		'unzip'
		'usbutils'
		'util-linux'
		'wget'
		'whiptail'
		'wireless-tools'
		'wpasupplicant'
		'wput'
		'zip'

	)

	# - Keyring specific:
	#	Raspbian
	if (( $HW_MODEL < 10 )); then

		aPACKAGES_REQUIRED_INSTALL+=('raspbian-archive-keyring')

	#	Debian
	else

		aPACKAGES_REQUIRED_INSTALL+=('debian-archive-keyring')

	fi

	# - HW_ARCH specific required packages
	#	x86_64
	if (( $HW_ARCH == 10 )); then

		aPACKAGES_REQUIRED_INSTALL+=('linux-image-amd64')
		aPACKAGES_REQUIRED_INSTALL+=('intel-microcode')
		aPACKAGES_REQUIRED_INSTALL+=('amd64-microcode')
		aPACKAGES_REQUIRED_INSTALL+=('firmware-linux-nonfree')
		aPACKAGES_REQUIRED_INSTALL+=('firmware-misc-nonfree')
		aPACKAGES_REQUIRED_INSTALL+=('grub-efi-amd64')
		#aPACKAGES_REQUIRED_INSTALL+=('dmidecode')

	fi

	# - HW_MODEL specific required packages
	#	RPi
	if (( $HW_MODEL < 10 )); then

		aPACKAGES_REQUIRED_INSTALL+=('libraspberrypi-bin')
		aPACKAGES_REQUIRED_INSTALL+=('libraspberrypi0')
		aPACKAGES_REQUIRED_INSTALL+=('raspberrypi-bootloader')
		aPACKAGES_REQUIRED_INSTALL+=('raspberrypi-kernel')
		aPACKAGES_REQUIRED_INSTALL+=('raspberrypi-sys-mods')
		aPACKAGES_REQUIRED_INSTALL+=('raspi-copies-and-fills')

	#	Odroid C2
	elif (( $HW_MODEL == 12 )); then

		aPACKAGES_REQUIRED_INSTALL+=('linux-image-arm64-odroid-c2')

	#	Odroid XU3/4
	elif (( $HW_MODEL == 11 )); then

		#aPACKAGES_REQUIRED_INSTALL+=('linux-image-4.9-armhf-odroid-xu3')
		aPACKAGES_REQUIRED_INSTALL+=('linux-image-armhf-odroid-xu3')

	#	Odroid C1
	elif (( $HW_MODEL == 10 )); then

		aPACKAGES_REQUIRED_INSTALL+=('linux-image-armhf-odroid-c1')

	#	Rock64
	elif (( $HW_MODEL == 43 )); then

		aPACKAGES_REQUIRED_INSTALL+=('linux-rock64-package')

	#	BBB
	elif (( $HW_MODEL == 71 )); then

		aPACKAGES_REQUIRED_INSTALL+=('device-tree-compiler') #Kern
		aPACKAGES_REQUIRED_INSTALL+=('dosfstools') #EMMC transfer

	fi

	dietpi-notify 2 "Generating list of minimal packages, required for DietPi installation:"

	INSTALL_PACKAGES=''
	for ((i=0; i<${#aPACKAGES_REQUIRED_INSTALL[@]}; i++))
	do

		#	One line INSTALL_PACKAGES so we can use it later.
		INSTALL_PACKAGES+="${aPACKAGES_REQUIRED_INSTALL[$i]} "

	done

	# - delete[]
	unset aPACKAGES_REQUIRED_INSTALL

	dietpi-notify 2 "Marking required packages as manually installed:"

	apt-mark manual $INSTALL_PACKAGES
	Error_Check

	dietpi-notify 2 "Purging APT with autoremoval:"

	apt-get autoremove --purge -y
	Error_Check


	#------------------------------------------------------------------------------------------------
	dietpi-notify 0 'Step 5: APT Installations:'
	#------------------------------------------------------------------------------------------------

	dietpi-notify 2 "Upgrading existing APT installed packages:"

	DEBIAN_FRONTEND='noninteractive' apt-get dist-upgrade -y
	Error_Check

	#???: WHIP_OPTIONal Reinstall OpenSSH (for updating dietpi scripts etc). Gets removed during finalise.
	# apt-get install openssh-server -y
	# echo -e "PermitRootLogin yes" >> /etc/ssh/sshd_config
	# systemctl restart ssh
	#???

	dietpi-notify 2 "Disabling swapfile generation for dphys-swapfile during install"

	echo -e "CONF_SWAPSIZE=0" > /etc/dphys-swapfile
	Error_Check


	dietpi-notify 2 "Installing core DietPi pre-req APT packages"
	dietpi-notify 2 "The following packages will be installed\n$INSTALL_PACKAGES"

	AGI $INSTALL_PACKAGES
	Error_Check

	dietpi-notify 2 "Onboard Bluetooth selection"

	WHIP_TITLE='Bluetooth Required?'
	WHIP_DESC='Please select an option'
	WHIP_DEFAULT_ITEM=0
	WHIP_MENU_ARRAY=(

		'0' 'BT not required, do not install.'
		'1' 'Device has onboard BT, and/or, I require BT functionality.'

	)

	Run_Whiptail
	if (( $WHIP_RETURN_VALUE == 1 )); then

		dietpi-notify 2 "Installing Bluetooth packages"

		AGI bluetooth bluez-firmware
		Error_Check


	fi


	if (( $HW_MODEL < 10 )); then

		dietpi-notify 2 "Installing Bluetooth packages specific to RPi"

		AGI pi-bluetooth
		Error_Check

	fi

	# - @MichaIng https://github.com/Fourdee/DietPi/pull/1266/files
	dietpi-notify 2 "Returning installation of recommends back to default"

	rm /etc/apt/apt-conf.d/99norecommends &> /dev/null

	#------------------------------------------------------------------------------------------------
	dietpi-notify 0 'Step 6: Downloading and installing DietPi sourcecode'
	#------------------------------------------------------------------------------------------------

	INTERNET_ADDRESS='https://github.com/Fourdee/DietPi/archive/testing.zip' #NB: testing until this is stable in master
	dietpi-notify 2 "Checking connection to $INTERNET_ADDRESS"
	Check_Connection "$INTERNET_ADDRESS"
	Error_Check

	wget "$INTERNET_ADDRESS" -O package.zip
	Error_Check

	dietpi-notify 2 "Extracting DietPi sourcecode"

	unzip package.zip
	Error_Check

	rm package.zip

	dietpi-notify 2 "Removing files not required"

	#	Remove files we do not require, or want to overwrite in /boot
	rm DietPi-*/CHANGELOG.txt
	rm DietPi-*/PREP_SYSTEM_FOR_DIETPI.sh
	rm DietPi-*/TESTING-BRANCH.md
	rm DietPi-*/uEnv.txt # Pine 64, use existing on system.

	dietpi-notify 2 "Creating /boot"

	mkdir -p /boot
	Error_Check

	dietpi-notify 2 "Moving to /boot"

	# - HW specific boot.ini uenv.txt
	if (( $HW_MODEL == 10 )); then

		mv DietPi-*/boot_c1.ini /boot/boot.ini
		Error_Check

	elif (( $HW_MODEL == 11 )); then

		mv DietPi-*/boot_xu4.ini /boot/boot.ini
		Error_Check

	elif (( $HW_MODEL == 12 )); then

		mv DietPi-*/boot_c2.ini /boot/boot.ini
		Error_Check

	fi

	rm DietPi-*/*.ini

	cp -R DietPi-*/* /boot/
	Error_Check

	dietpi-notify 2 "Cleaning up extracted files"

	rm -R DietPi-*
	Error_Check

	dietpi-notify 2 "Setting execute permissions for /boot/dietpi"

	chmod -R +x /boot/dietpi
	Error_Check

	#------------------------------------------------------------------------------------------------
	dietpi-notify 0 "Step 7: Prep system for DietPi ENV:"
	#------------------------------------------------------------------------------------------------

	dietpi-notify 2 "Deleting list of known users, not required by DietPi"

	userdel -f pi &> /dev/null
	userdel -f test &> /dev/null #armbian
	userdel -f odroid &> /dev/null
	userdel -f rock64 &> /dev/null
	userdel -f linaro &> /dev/null #ASUS TB
	userdel -f dietpi &> /dev/null
	userdel -f debian &> /dev/null #BBB

	dietpi-notify 2 "Removing misc files/folders, not required by DietPi"

	rm -R /home &> /dev/null
	rm -R /media &> /dev/null

	rm -R /usr/share/fonts/* &> /dev/null
	rm -R /usr/share/icons/* &> /dev/null

	#rm /etc/apt/sources.list.d/armbian.list
	rm /etc/init.d/resize2fs &> /dev/null
	rm /etc/update-motd.d/* &> /dev/null # ARMbian

	systemctl disable firstrun  &> /dev/null
	rm /etc/init.d/firstrun  &> /dev/null # ARMbian

	# - Disable ARMbian's log2ram: https://github.com/Fourdee/DietPi/issues/781
	systemctl disable log2ram.service &> /dev/null
	systemctl stop log2ram.service &> /dev/null
	rm /usr/local/sbin/log2ram &> /dev/null
	rm /etc/systemd/system/log2ram.service &> /dev/null
	systemctl daemon-reload &> /dev/null
	rm /etc/cron.hourly/log2ram &> /dev/null

	rm /etc/init.d/cpu_governor &> /dev/null# Meveric
	rm /etc/systemd/system/cpu_governor.service &> /dev/null# Meveric

	# -Disable ARMbian's resize service (not automatically removed by ARMbian scripts...)
	systemctl disable resize2fs &> /dev/null
	rm /etc/systemd/system/resize2fs.service &> /dev/null

	# -ARMbian-config
	rm /etc/profile.d/check_first_login_reboot.sh &> /dev/null

	dietpi-notify 2 "Setting UID bit for sudo"

	# - https://github.com/Fourdee/DietPi/issues/794
	chmod 4755 /usr/bin/sudo
	Error_Check

	dietpi-notify 2 "Creating DietPi system directories"

	# - Create DietPi common folders
	mkdir -p /DietPi
	Error_Check

	mkdir -p /etc/dietpi
	Error_Check

	mkdir -p /mnt/dietpi_userdata
	Error_Check

	mkdir -p /mnt/samba
	Error_Check

	mkdir -p /mnt/ftp_client
	Error_Check

	mkdir -p /mnt/nfs_client
	Error_Check

	echo -e "Samba client can be installed and setup by DietPi-Config.\nSimply run: dietpi-config and select the Networking WHIP_OPTIONs: NAS/Misc menu" > /mnt/samba/readme.txt
	echo -e "FTP client mount can be installed and setup by DietPi-Config.\nSimply run: dietpi-config and select the Networking WHIP_OPTIONs: NAS/Misc menu" > /mnt/ftp_client/readme.txt
	echo -e "NFS client can be installed and setup by DietPi-Config.\nSimply run: dietpi-config and select the Networking WHIP_OPTIONs: NAS/Misc menu" > /mnt/nfs_client/readme.txt

	dietpi-notify 2 "Deleting all log files /var/log"

	/boot/dietpi/dietpi-logclear 2 &> /dev/null # As this will report missing vars, however, its fine, does not break functionality.

	dietpi-notify 2 "Generating DietPi /etc/fstab"

	/boot/dietpi/dietpi-drive_manager 4
	Error_Check

	dietpi-notify 2 "Installing and starting DietPi-RAMdisk service"

	cat << _EOF_ > /etc/systemd/system/dietpi-ramdisk.service
[Unit]
Description=DietPi-RAMdisk
After=local-fs.target

[Service]
Type=forking
RemainAfterExit=yes
ExecStartPre=/bin/mkdir -p /etc/dietpi/logs
ExecStart=/bin/bash -c '/boot/dietpi/dietpi-ramdisk 0'
ExecStop=/bin/bash -c '/DietPi/dietpi/dietpi-ramdisk 1'

[Install]
WantedBy=local-fs.target
_EOF_
	systemctl enable dietpi-ramdisk.service
	systemctl daemon-reload
	systemctl start dietpi-ramdisk.service
	Error_Check

	dietpi-notify 2 "Installing and starting DietPi-RAMlog service"

	#	DietPi-Ramlog
	cat << _EOF_ > /etc/systemd/system/dietpi-ramlog.service
[Unit]
Description=DietPi-RAMlog
Before=rsyslog.service syslog.service
After=local-fs.target

[Service]
Type=forking
RemainAfterExit=yes
ExecStart=/bin/bash -c '/boot/dietpi/dietpi-ramlog 0'
ExecStop=/bin/bash -c '/DietPi/dietpi/dietpi-ramlog 1'

[Install]
WantedBy=local-fs.target
_EOF_
	systemctl enable dietpi-ramlog.service
	systemctl daemon-reload
	systemctl start dietpi-ramlog.service
	Error_Check

	dietpi-notify 2 "Installing DietPi boot service"

	#	Boot
	cat << _EOF_ > /etc/systemd/system/dietpi-boot.service
[Unit]
Description=DietPi-Boot
After=network-online.target network.target networking.service dietpi-ramdisk.service dietpi-ramlog.service
Requires=dietpi-ramdisk.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c '/DietPi/dietpi/boot'
StandardOutput=tty

[Install]
WantedBy=multi-user.target
_EOF_
	systemctl enable dietpi-boot.service
	systemctl daemon-reload

	dietpi-notify 2 "Installing DietPi /etc/rc.local service"

	update-rc.d -f rc.local remove &> /dev/null
	rm /etc/init.d/rc.local &> /dev/null
	rm /lib/systemd/system/rc-local.service &> /dev/null

	cat << _EOF_ > /etc/systemd/system/rc-local.service
[Unit]
Description=/etc/rc.local Compatibility
After=dietpi-boot.service dietpi-ramdisk.service dietpi-ramlog.service
Requires=dietpi-boot.service dietpi-ramdisk.service

[Service]
Type=idle
ExecStart=/etc/rc.local
StandardOutput=tty
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
_EOF_
	systemctl enable rc-local.service
	systemctl daemon-reload

	cat << _EOF_ > /etc/rc.local
#!/bin/bash
#Precaution: Wait for DietPi Ramdisk to finish
while [ ! -f /DietPi/.ramdisk ]
do

    /DietPi/dietpi/func/dietpi-notify 2 "Waiting for DietPi-RAMDISK to finish mounting DietPi to RAM..."
    sleep 1

done

echo -e "\$(cat /proc/uptime | awk '{print \$1}') Seconds" > /var/log/boottime
if (( \$(cat /DietPi/dietpi/.install_stage) == 1 )); then

    /DietPi/dietpi/dietpi-services start

fi
/DietPi/dietpi/dietpi-banner 0
echo -e " Default Login:\n Username = root\n Password = dietpi\n"
exit 0
_EOF_
	chmod +x /etc/rc.local
	systemctl daemon-reload

	dietpi-notify 2 "Installing kill-ssh-user-sessions-before-network.service"

	cat << _EOF_ > /etc/systemd/system/kill-ssh-user-sessions-before-network.service
[Unit]
Description=Shutdown all ssh sessions before network
DefaultDependencies=no
Before=network.target shutdown.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'killall sshd &> /dev/null; killall dropbear &> /dev/null'

[Install]
WantedBy=poweroff.target halt.target reboot.target
_EOF_
	systemctl enable kill-ssh-user-sessions-before-network
	systemctl daemon-reload

	dietpi-notify 2 "Configuring Cron:"

	#Cron jobs
	cp /DietPi/dietpi/conf/cron.daily_dietpi /etc/cron.daily/dietpi
	Error_Check
	chmod +x /etc/cron.daily/dietpi
	Error_Check
	cp /DietPi/dietpi/conf/cron.hourly_dietpi /etc/cron.hourly/dietpi
	Error_Check
	chmod +x /etc/cron.hourly/dietpi
	Error_Check

	cat << _EOF_ > /etc/crontab
#Please use dietpi-cron to change cron start times
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# m h dom mon dow user  command
17 *    * * *   root    cd / && run-parts --report /etc/cron.hourly
25 1    * * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )
47 1    * * 7   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.weekly )
52 1    1 * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.monthly )
_EOF_
	Error_Check

	# - ntp
	rm /etc/cron.daily/ntp &> /dev/null

	dietpi-notify 2 "Disabling apt-daily services (prevents random APT cache lock):"

	systemctl mask apt-daily.service
	systemctl mask apt-daily-upgrade.timer

	dietpi-notify 2 "Setting vm.swappiness=1:"

	sed -i 's/vm.swappiness=/d' /etc/sysctl.conf
	echo -e "vm.swappiness=1" > /etc/sysctl.d/97-dietpi.conf
	Error_Check

	dietpi-notify 2 "Configuring Network:"

	rm -R /etc/network/interfaces &> /dev/null # armbian symlink for bulky network-manager
	cp /boot/dietpi/conf/network_interfaces /etc/network/interfaces
	/DietPi/dietpi/func/obtain_network_details
	Error_Check
	# - enable allow-hotplug eth0 after copying.
	sed -i "/allow-hotplug eth/c\allow-hotplug eth$(sed -n 1p /DietPi/dietpi/.network)" /etc/network/interfaces

	dietpi-notify 2 "Tweaking DHCP timeout:"

	# - Reduce DHCP request retry count and timeouts: https://github.com/Fourdee/DietPi/issues/711
	sed -i '/^#timeout /d' /etc/dhcp/dhclient.conf
	sed -i '/^#retry /d' /etc/dhcp/dhclient.conf
	sed -i '/^timeout /d' /etc/dhcp/dhclient.conf
	sed -i '/^retry /d' /etc/dhcp/dhclient.conf
	cat << _EOF_ >> /etc/dhcp/dhclient.conf
timeout 10;
retry 4;
_EOF_
	Error_Check

	dietpi-notify 2 "Tweaking network naming:"

	# - Prefer to use wlan/eth naming for networked devices (eg: stretch)
	ln -sf /dev/null /etc/systemd/network/99-default.link
	#??? x86_64
	#	kernel cmd line with GRUB
	#	/etc/default/grub [replace] GRUB_CMDLINE_LINUX="net.ifnames=0"
	#								GRUB_TIMEOUT=0
	#???

	dietpi-notify 2 "Configuring Hosts:"

	cat << _EOF_ > /etc/hosts
127.0.0.1    localhost
127.0.1.1    DietPi
::1          localhost ip6-localhost ip6-loopback
ff02::1      ip6-allnodes
ff02::2      ip6-allrouters
_EOF_
	Error_Check

	cat << _EOF_ > /etc/hostname
DietPi
_EOF_
	Error_Check


	dietpi-notify 2 "Configuring htop:"

	#	NB: Also done in finalize
	mkdir -p /root/.config/htop
	cp /DietPi/dietpi/conf/htoprc /root/.config/htop/htoprc


	dietpi-notify 2 "Configuring hdparm:"

	cat << _EOF_ >> /etc/hdparm.conf

#DietPi external USB drive. Power management settings.
/dev/sda {
        #10 mins
        spindown_time = 120

        #
        apm = 254
}
_EOF_
	Error_Check

	dietpi-notify 2 "Configuring bash:"

	cat << _EOF_ >> /etc/bash.bashrc
#LANG
export \$(cat /etc/default/locale | grep LANG=)

#Define a default LD_LIBRARY_PATH for all systems
export LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib:/opt/vc/lib

#DietPi Additions
alias sudo='sudo ' # https://github.com/Fourdee/DietPi/issues/424
alias dietpi-process_tool='/DietPi/dietpi/dietpi-process_tool'
alias dietpi-letsencrypt='/DietPi/dietpi/dietpi-letsencrypt'
alias dietpi-autostart='/DietPi/dietpi/dietpi-autostart'
alias dietpi-cron='/DietPi/dietpi/dietpi-cron'
alias dietpi-launcher='/DietPi/dietpi/dietpi-launcher'
alias dietpi-cleaner='/DietPi/dietpi/dietpi-cleaner'
alias dietpi-morsecode='/DietPi/dietpi/dietpi-morsecode'
alias dietpi-sync='/DietPi/dietpi/dietpi-sync'
alias dietpi-backup='/DietPi/dietpi/dietpi-backup'
alias dietpi-bugreport='/DietPi/dietpi/dietpi-bugreport'
alias dietpi-services='/DietPi/dietpi/dietpi-services'
alias dietpi-config='/DietPi/dietpi/dietpi-config'
alias dietpi-software='/DietPi/dietpi/dietpi-software'
alias dietpi-update='/DietPi/dietpi/dietpi-update'
alias dietpi-drive_manager='/DietPi/dietpi/dietpi-drive_manager'
alias emulationstation='/opt/retropie/supplementary/emulationstation/emulationstation'
alias opentyrian='/usr/local/games/opentyrian/run'

alias cpu='/DietPi/dietpi/dietpi-cpuinfo'
alias dietpi-logclear='/DietPi/dietpi/dietpi-logclear'
treesize()
{
     du -k --max-depth=1 | sort -nr | awk '
     BEGIN {
        split("KB,MB,GB,TB", Units, ",");
     }
     {
        u = 1;
        while (\$1 >= 1024)
        {
           \$1 = \$1 / 1024;
           u += 1;
        }
        \$1 = sprintf("%.1f %s", \$1, Units[u]);
        print \$0;
     }
    '
}
_EOF_
	Error_Check

	# - login,
	sed -i '/DietPi/d' /root/.bashrc #prevents dupes
	echo -e "\n/DietPi/dietpi/login" >> /root/.bashrc
	Error_Check

	dietpi-notify 2 "Configuring fakehwclock:"

	# - allow times in the past
	sed -i "/FORCE=/c\FORCE=force" /etc/default/fake-hwclock

	dietpi-notify 2 "Configuring serial consoles:"

	# - Disable serial console
	/DietPi/dietpi/func/dietpi-set_hardware serialconsole disable

	dietpi-notify 2 "Configuring ntpd:"

	systemctl disable systemd-timesyncd
	rm /etc/init.d/ntp &> /dev/null

	dietpi-notify 2 "Configuring regional settings (TZ/Locale/Keyboard):"

	#TODO: automate these...
	dpkg-reconfigure tzdata #Europe > London
	dpkg-reconfigure keyboard-configuration #Keyboard must be plugged in for this to work!
	dpkg-reconfigure locales # en_GB.UTF8 as default and only installed locale


	# - Pump default locale into sys env: https://github.com/Fourdee/DietPi/issues/825
	cat << _EOF_ > /etc/environment
LC_ALL=en_GB.UTF-8
LANG=en_GB.UTF-8
_EOF_
	Error_Check

	#HW_ARCH specific
	dietpi-notify 2 "Applying HW_ARCH specific tweaks:"

	if (( $HW_ARCH == 10 )); then

		# - i386 APT support
		dpkg --add-architecture i386
		apt-get update

		# - Disable nouveau: https://github.com/Fourdee/DietPi/issues/1244 // http://dietpi.com/phpbb/viewtopic.php?f=11&t=2462&p=9688#p9688
		cat << _EOF_ > /etc/modprobe.d/blacklist-nouveau.conf
blacklist nouveau
blacklist lbm-nouveau
options nouveau modeset=0
alias nouveau off
alias lbm-nouveau off
_EOF_
		echo -e "options nouveau modeset=0" > /etc/modprobe.d/nouveau-kms.conf
		update-initramfs -u

	fi

	#HW_MODEL specific
	dietpi-notify 2 "Appling HW_MODEL specific tweaks:"

	# - ARMbian OPi Zero 2: https://github.com/Fourdee/DietPi/issues/876#issuecomment-294350580
	if (( $HW_MODEL == 35 )); then

		echo -e "blacklist bmp085" > /etc/modprobe.d/bmp085.conf

	# - Sparky SBC ONLY: Blacklist GPU and touch screen modules: https://github.com/Fourdee/DietPi/issues/699#issuecomment-271362441
	elif (( $HW_MODEL == 70 )); then

		cat << _EOF_ > /etc/modprobe.d/disable_sparkysbc_touchscreen.conf
blacklist owl_camera
blacklist gsensor_stk8313
blacklist ctp_ft5x06
blacklist ctp_gsl3680
blacklist gsensor_bma222
blacklist gsensor_mir3da
_EOF_

		cat << _EOF_ > /etc/modprobe.d/disable_sparkysbc_gpu.conf
blacklist pvrsrvkm
blacklist drm
blacklist videobuf2_vmalloc
blacklist bc_example
_EOF_

	# - RPI: Scroll lock fix for RPi by Midwan: https://github.com/Fourdee/DietPi/issues/474#issuecomment-243215674
	elif (( $HW_MODEL < 10 )); then

		cat << _EOF_ > /etc/udev/rules.d/50-leds.rules
ACTION=="add", SUBSYSTEM=="leds", ENV{DEVPATH}=="*/input*::scrolllock", ATTR{trigger}="kbd-scrollock"
_EOF_

	# - PINE64 (and possibily others): Cursor fix for FB
	elif (( $HW_MODEL >= 40 && $HW_MODEL <= 42 )); then

		cat << _EOF_ >> "$HOME"/.bashrc
infocmp > terminfo.txt
sed -i -e 's/?0c/?112c/g' -e 's/?8c/?48;0;64c/g' terminfo.txt
tic terminfo.txt
tput cnorm
_EOF_

	# - XU4 FFMPEG fix. Prefer debian.org over Meveric for backports: https://github.com/Fourdee/DietPi/issues/1273
	elif (( $HW_MODEL == 11 )); then

		cat << _EOF_ > /etc/apt/preferences.d/backports
Package: *
Pin: release a=jessie-backports
Pin: origin "fuzon.co.uk"
Pin-Priority: 99
_EOF_

	fi

	# - ARMbian increase console verbose
	sed -i '/verbosity=/c\verbosity=7' /boot/armbianEnv.txt &> /dev/null


	#------------------------------------------------------------------------------------------------
	dietpi-notify 0 "Step 8: Finalise system for first run of DietPi:"
	#------------------------------------------------------------------------------------------------

	#Finalise system
	/DietPi/dietpi/finalise

	dietpi-notify 0 "Completed, disk can now be saved to .img for later use, or, reboot system to start first run of DietPi:"

	#Power off system

	#Read image

	#Resize rootfs parition to mininum size +50MB

}
