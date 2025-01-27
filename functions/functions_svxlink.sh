#!/bin/bash
################################################################################
# DEFINE SVXLINK FUNCTIONS
################################################################################
#####################################################################
# Based on: https://github.com/sm0svx/svxlink/wiki/InstallSrcDebian
#####################################################################

function install_svxlink_source () {
	#####################################################################
	echo "--------------------------------------------------------------"
	echo " Compile/Install SVXLink from Source Code (ver $SVXLINK_VER)"
	echo "--------------------------------------------------------------"
	#####################################################################

	##################################	
	echo "--------------------------"
	echo " Install SVXLINK required packages"
	echo "--------------------------"
	##################################
		
 	apt update && apt upgrade -y --fix-missing
	
	args=(
	--assume-yes 
	--fix-missing
    alsa-utils   			# required for configuring sound levels / card settings
	cmake   				# required to build only
	#doxygen 	 			# optional for developer documentation
	g++ 					# required to build only
	gpiod 					# should be redundant to libgpiod-dev
	groff   				# recommended - for man pages
	make   					# required to build only
	libasound2-dev   		# required for alsa support
	libcurl4-openssl-dev  	# required for builds
	libgcrypt20-dev   		# required for cryptographic functions
    libgsm1-dev   			# required for GSM audio codec
	libgpiod-dev   			# required for modern GPIO support
	libjsoncpp-dev   		# required for json file support
	libpopt-dev        			# required - parse command line options - unavailable in bookworm
	libogg-dev 		  		# unknown useage
	libopus-dev	   			# unknown useage
	librtlsdr-dev   		# optional for RTL2832U DVB-T/SDR USB dongles
	libsigc++-2.0-dev   	# required
	libspeex-dev   			# optional - Speex audio codec
	#tar  					# recommended for unpacking (part of OS now)
	#opus-tools     		# optional - for Opus sound files  (unused for ORP)
	tcl-dev  				# required for scripting
	#libqt          		# optional - framework for graphical applications (unused for ORP)
	)
	apt install  "${args[@]}"
	
	
	
	#########openrepeater residuals in cross comparisons - believed unneeded, but noted just in case
	
	#libgpiod2 \
	#pigpiod \
	#libjsoncpp25 \
	#libpopt-dev \
	#tcl8.6-dev \
	#unzip \
	#zip \
	#libpigpiod-if-dev \
	#libpigpiod-if2-1 \
	#vorbis-tools \
	#curl \
	#git \
	

	################################################
    echo "----------------------------------------"
	echo " Add svxlink user and add to user groups"
	echo "----------------------------------------"
	###############################################
	
	useradd -r svxlink
	usermod -a -G daemon,gpio,audio svxlink

	##########################################
	echo "-----------------------------------"
	echo " Download and compile from source, "
	echo " either the trunk or latest package"
	echo "-----------------------------------"
	##########################################

	cd "/usr/src"
	echo "svx_trunk=$1"
	
	if [ "$1" = "svx_trunk" ]; then
		##########################################
		echo "---------------------------"
		echo "Building SVXLINK from Trunk"
		echo "---------------------------"
		##########################################

		git clone https://github.com/sm0svx/svxlink.git
		cd svxlink/src

		echo "Completed"
	else
		############################################
		echo "-------------------------------------"	
		echo "building svxlink from release version"
		echo "-------------------------------------"
		############################################
		
		curl -Lo svxlink-source.tar.gz "https://github.com/sm0svx/svxlink/archive/$SVXLINK_VER.tar.gz"
		tar xvzf svxlink-source.tar.gz
		cd svxlink-"$SVXLINK_VER"/src
		
		echo "Completed"
	fi

	############################################
	echo "-------------------------------------"	
	echo " If Selected, enable the non-standard"
	echo " modulesto be included in the build "
	echo " process"
	echo "-------------------------------------"
	############################################
	
	echo "USE_CONTRIBS=$2"
	if [ "$2" = "USE_CONTRIBS" ]; then
		echo "Entering config to enable optional contrib modules"
		Modules_Build_Cmake_switches=' -DWITH_CONTRIB_MODULE_REMOTE_RELAY=ON -DWITH_CONTRIB_MODULE_SITE_STATUS=ON -DWITH_CONTRIB_MODULE_TCLSSTV=ON -DWITH_CONTRIB_MODULE_TXFAN=ON '

		echo "Completed"
		
	else
	
		############################################
		echo "-------------------------------------"
		echo "Optional contrib modules not selected"
		echo "-------------------------------------"
		############################################
				
		Modules_Build_Cmake_switches=""

		echo "Completed"
	fi

	############################################
	echo "-------------------------------------"	
	echo "building svxlink "
	echo "-------------------------------------"
	############################################
	
	mkdir build
	cd build
	echo "make command: cmake -DCMAKE_INSTALL_PREFIX=/usr -DSYSCONF_INSTALL_DIR=/etc -DLOCAL_STATE_DIR=/var -DWITH_SYSTEMD=ON -DUSE_QT=no $Modules_Build_Cmake_switches -S.. -B."
	cmake -DCMAKE_INSTALL_PREFIX=/usr -DSYSCONF_INSTALL_DIR=/etc -DLOCAL_STATE_DIR=/var -DWITH_SYSTEMD=ON -DUSE_QT=no $Modules_Build_Cmake_switches -S.. -B.
	
	make -j5
	make doc

	echo "Completed"

	############################################
	echo "-------------------------------------"	
	echo "Installing SVXLink "
	echo "-------------------------------------"
	############################################
	
	make install
	ldconfig

	echo "Completed"

	############################################
	echo "-------------------------------------"	
	echo "Enable/Disable SVXLink Services "
	echo "-------------------------------------"
	############################################

	systemctl enable svxlink
	systemctl disable remotetrx
	
	echo "Completed"

	############################################
	echo "-------------------------------------"	
	echo "Clean Up Build Dir                   "
	echo "-------------------------------------"
	############################################
	
	cd /
	rm -rf /usr/src/svxlink*

	echo "Completed"
}

function fix_svxlink_gpio {
	#####################################################################
	echo "--------------------------------------------------------------"
	echo " Apply Fixes to SVXLink GPIO Support until corrected          "
	echo "--------------------------------------------------------------"
	#####################################################################

	sed -i -e 's/$GPIOPATH/$GPIO_PATH/g' /usr/sbin/svxlink_gpio_up

	#####################################################################
	echo "--------------------------------------------------------------"
	echo " Apply SystemD Fixes to SVXLink GPIO Service                  "
	echo "--------------------------------------------------------------"
	#####################################################################
	
	sed -i /lib/systemd/system/svxlink_gpio_setup.service -e "s#Documentation=man:svxlink(1)#\
	Documentation=man:svxlink(1)\n\
	\#fix to address the gpio not exporting at boot\n\
	Requires=systemd-modules-load.service\n\
	After=systemd-modules.load.service\n\
	After=network.target\n\
	Before=sysvinit.target\n\
	ConditionPathExists=/sys/class/i2c-adapter#"

	echo "Completed"
}
################################################################################
function install_svxlink_sounds {
	#####################################################################
	echo "--------------------------------------------------------------"
	echo " Installing ORP Version of SVXLink Sounds (US English)        "
	echo "--------------------------------------------------------------"
	#####################################################################

	cd "$wrk_dir"
	wget https://github.com/OpenRepeater/orp-sounds/archive/2019.zip
	unzip 2019.zip
	mkdir -p "$SVXLINK_SOUNDS_DIR"
	mv orp-sounds-2019/en_US "$SVXLINK_SOUNDS_DIR"
	rm -R orp-sounds-2019
	rm 2019.zip
	
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/0.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_0.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/1.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_1.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/2.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_2.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/3.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_3.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/4.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_4.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/5.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_5.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/6.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_6.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/7.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_7.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/8.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_8.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/9.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/phonetic_9.wav"	
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/O.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/oX.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/MetarInfo/hours.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/hours.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/MetarInfo/hour.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/hour.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/Hz.wav" "$SVXLINK_SOUNDS_DIR/en_US/Core/hz.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Core/repeater.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/repeater.wav"
	ln -s "$SVXLINK_SOUNDS_DIR/en_US/Default/O.wav" "$SVXLINK_SOUNDS_DIR/en_US/Default/o.wav"
	echo "Completed"
}

function force_async_audio_zerfill {
	ENVIRONMENT_FILE="/etc/default/svxlink"
	REPLACEMENT_VALUE="1"
	sed -i "s/\(ASYNC_AUDIO_ALSA_ZEROFILL *= *\).*/\1$REPLACEMENT_VALUE/" "$ENVIRONMENT_FILE"
	
	echo "Completed"
}

function logic_fixup {

	#####################################################################
    echo "--------------------------------------------------------------"
    echo " SVXLink Logic Fix Up                                         "
    echo "--------------------------------------------------------------"
    #####################################################################

	# change to the top level directory
	cd / || return
	
	#find the desired function
	InputFileName="$1"
	if [ -z "$InputFileName" ]; then
	  echo "parameter 'InputFileName' was not entered"
	  echo "Usage= ./Logic_fixup.sh <input file path> \"proc <function name>\" <output file path>"
	  echo "it is assumed the input file path is an absolute path"
	  return -1
	fi  
	if  ! [ -f "$InputFileName"  ]; then
	  echo "parameter \'InputFileName\' is not a valid file path"
	  echo "it is assumed the input file path is an absolute path"
	  return -1
	else
	  echo "$InputFileName is a valid path"
	fi

	FunctionName="$2"
	if [ -z "$FunctionName" ]; then
	  echo "parameter 'FunctionName' was not entered"
	  return -1
	else
	  echo "FunctionName is '$FunctionName'"
	fi

	OutputFileName="$3"
	if [ -z "$OutputFileName" ]; then
	  echo "parameter 'OutputFileName' was not entered"
	else
	  echo "OutputFileName is $OutputFileName"
	fi

	#Locate the begining of the function
	file="$InputFileName"
	StartLine=1
	while IFS= read -r line
	do
	#echo $line
	  
	  if [[ "$line" == *"$FunctionName"* ]]; then
		break
	  fi
	  ((StartLine++))
	done <"$file"
	echo "StartLine: $StartLine"

	#Locate the start of the next function
	NextStart=0
	while IFS= read -r line
	do
	  #make sure we are not looking in the wrong place
	  if (($NextStart > (($StartLine )))) && [[ $line == *"proc "* ]]; then
		break;
	  fi
	  ((NextStart++))
	done <"$file"
	echo "NextStart: $NextStart"

	# we should now have the starting line of the desired function, and the start of the next function.
	# Now we need to comment out the respective lines of code leaving the desired function effectively
	# empty
	CurrentLine=0

	# process the file
	while IFS= read -r line
	do
	  #echo $CurrentLine
	  if  (( $CurrentLine >= $StartLine )) && [[ $line != '}' ]] && [[ $line != "" ]] && [[ ${line:0:1} != '#' ]] && [[ (($CurrentLine < $NextStart)) ]]; then   

		echo "#$line" >> "$OutputFileName"".tmp"
	  else
		echo "$line" >> "$OutputFileName"".tmp"
	  fi
	  
	  ((CurrentLine++))
	done <"$file"
	
	mv "$OutputFileName"".tmp" "$OutputFileName"
	
	echo "Completed"
}

function install_device_permission_scripts {
	#####################################################################
	echo "--------------------------------------------------------------"
	echo " Copy Permissions Scripts for Hidraw/Serial Devices into place"
	echo "--------------------------------------------------------------"
	#####################################################################
	
	cp "$SCRIPT_DIR/install/scripts/devices.conf" "/etc/svxlink/"
	cp "$SCRIPT_DIR/install/scripts/svxlink_devices" "/usr/sbin/"
	cp "$SCRIPT_DIR/install/scripts/svxlink_devices.service" "/lib/systemd/system/"
	chown www-data:www-data "/etc/svxlink/devices.conf"
	chmod +x "/usr/sbin/svxlink_devices"
	
	echo "Completed"
}
