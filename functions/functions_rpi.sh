#!/bin/bash

################################################################################
# DEFINE RPI SPECIFIC FUNCTIONS
################################################################################

function rpi_disables {
    if [ "$system_arch" == "armhf" ] || [ "$system_arch" == "arm64" ]; then
    
    	######################################################################
    	echo "--------------------------------------------------------------"
        echo " Disable onboard HDMI sound card not used in OpenRepeater     "
        echo "--------------------------------------------------------------"
        ######################################################################
        
        sed -i $RPI_config_text_path -e"s#dtoverlay=vc4-kms-v3d#\#dtoverlay=vc4-kms-v3d#"

        echo "Completed"

        ######################################################################
        echo "--------------------------------------------------------------"
        echo " Disable onboard audio not used in OpenRepeater               "
        echo "--------------------------------------------------------------"
        ######################################################################
        
        sed -i $RPI_config_text_path -e"s#dtparam=audio=on#\#dtparam=audio=on#"

        echo "Completed"

        ######################################################################
        echo "--------------------------------------------------------------"
    	echo " Disable max_framebuffer not used in OpenRepeater             "
        echo "--------------------------------------------------------------"
        ######################################################################
        
        sed -i $RPI_config_text_path -e"s#max_framebuffers=2#\#max_framebuffers=2#"
        
        echo "Completed"
        
        ######################################################################        
        echo "--------------------------------------------------------------"
        echo " Disable CSI Camera port onboard not used in OpenRepeater     "
        echo "--------------------------------------------------------------"        
        ######################################################################
        
        sed -i $RPI_config_text_path -e"s#camera_auto_detect=1#\#camera_auto_detect=1#"
        
        echo "Completed"
        
        ######################################################################
        echo "--------------------------------------------------------------"
        echo " Disable DSI display used in OpenRepeater                     "
        echo "--------------------------------------------------------------"       
        ######################################################################
        sed -i $RPI_config_text_path -e"s#display_auto_detect=1#\#display_auto_detect=1#"
        
        echo "Completed"

        ######################################################################        
        echo "--------------------------------------------------------------"
        echo " Disable video overscan not used in OpenRepeater              "
        echo "--------------------------------------------------------------"
        ######################################################################
        
        sed -i $RPI_config_text_path -e"s#disable_overscan=1#\#disable_overscan=1#"
        
        echo "Completed"

        ######################################################################
        echo "--------------------------------------------------------------"
        echo " Disable BlueTooth not used in OpenRepeater                   "
        echo "--------------------------------------------------------------"
        ######################################################################
        
        cat >> $RPI_config_text_path <<- DELIM
			####################################################
			# Disable Onboard BlueTooth not used in OpenRepeater 
			####################################################
			dtoverlay=disable-bt    
			DELIM
			
		echo "Completed"	
    fi   
}

