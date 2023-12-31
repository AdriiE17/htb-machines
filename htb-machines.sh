#!/bin/bash

# Colours
GREEN="\e[0;32m\033[1m"
END="\033[0m\e[0m"
RED="\e[0;31m\033[1m"
BLUE="\e[0;34m\033[1m"
YELLOW="\e[0;33m\033[1m"
PURPLE="\e[0;35m\033[1m"
TURQUOISE="\e[0;36m\033[1m"
GRAY="\e[0;37m\033[1m"
BLACK="\e[0;30m"
ORANGE="\e[1;38;5;208m"

# Handling ctrl+c
ctrl_c() {
echo -e "\n\n${RED}Exiting...${END}\n"
    tput cnorm && exit 1
}
trap ctrl_c SIGINT


# For showing the error status of a command that fails in the middle of a sequence of pipelines
set -o pipefail

# Global variables
url_bundle="https://htbmachines.github.io/bundle.js" 

helpPanel() {
    # Info
    echo -e "\n${PURPLE}Searches HTB machines.${END}"
    echo -e "\n${RED}Usage: ${END}${GREEN}htb-machines${END} ${TURQUOISE}[OPTIONS]${END}"
    
    # Options
    echo -e "\n${RED}Options:${END}"
    echo -e "\t${TURQUOISE}-m${END}${GRAY}\tshow the properties for a given machine name.${END}"
    echo -e "\t${TURQUOISE}-i${END}${GRAY}\tgets a machine name by using its IP.${END}"
    echo -e "\t${TURQUOISE}-y${END}${GRAY}\tget the video write-up in YouTube.${END}"
    echo -e "\t${TURQUOISE}-d${END}${GRAY}\tget all machines that have the given difficulty. There are four types of difficulty: ${GREEN}fácil${END}${GRAY},${END} ${YELLOW}media${END}${GRAY},${END} ${ORANGE}difícil${END} ${GRAY}and${END} ${RED}insane${END}${GRAY}.${END}"
    echo -e "\t${TURQUOISE}-o${END}${GRAY}\tget all machines that have the given operating system. There are two possible OS: ${GREEN}linux${END} ${GRAY}and${END} ${BLUE}windows${END}${GRAY}.${END}"
    echo -e "\t${TURQUOISE}-s${END}${GRAY}\tget all machines that requires the given skill to be solved.${END}"
    echo -e "\t${TURQUOISE}-u${END}${GRAY}\tupdates necessary files.${END}"
    echo -e "\t${TURQUOISE}-h${END}${GRAY}\tshows this help panel.${END}"
}


# ---------- Functions for getting a specific machine or property ----------

# Returns the properties for a given machine name
getMachineProperties() {
    local machine_name="$1"

    machine_properties="$( ( awk "BEGIN{IGNORECASE = 1;}/name: \"${machine_name}\"/,/resuelta:/" bundle.js | grep -vE "id:|sku:|resuelta:" | tr -d "\"" | tr -d "," | sed 's/^ *//' ) 2>/dev/null )"
    
    # Checking for possible errors with the last commands
    if [ $? -ne 0 ]; then
        echo -e "\n${RED}Machine${END} ${GRAY}${machine_name}${END}${RED} not found :(\nUse${END} ${GREEN}htb-machines -u${END}${RED} and try again. If the error continues then probably ${END}${GRAY}${machine_name}${END}${RED} machine does not yet exist.${END}\n"
        exit 1
    fi

    echo -e "\n${PURPLE}Showing the properties of the machine ${END}${RED}${machine_name}${END}${PURPLE}:${END}"
    
    while read line; do
        properties_names="$(echo "${line}" | cut -d ' ' -f 1)"
        properties_values="$(echo "${line}" | cut -d ' ' -f 2-)"
        echo -e "\t${TURQUOISE}${properties_names}${EN} ${GRAY}${properties_values}${END}"
    done <<< ${machine_properties}
}

# Gets the machine name by using its IP
getMachineByIP() {
    local machine_ip="$1"
    local machine_name="$( grep -i "ip: \"${machine_ip}\"" -B 3 bundle.js | grep "name:" | awk '{print $NF}' | tr -d '"' | tr -d ',' )"
    
    # If machine_name is empty, then the IP is not valid
    if [ ! "$machine_name" ]; then
        echo -e "\n${RED}The IP ${END}${GRAY}${machine_ip}${END}${RED} is not correct or does not exist. Please enter another IP.${END}\n"
        exit 1
    fi

    echo -e "\n${PURPLE}The IP${END} ${RED}${machine_ip}${END} ${PURPLE}corresponds to the machine${END} ${RED}${machine_name}${END}${PURPLE}.${END}"
}

getYoutubeLink() {
    local  machine_name="$1"
    properties_list="$( getMachineProperties ${machine_name} )"
    
    if [ $? -ne 0 ]; then
        echo "$properties_list"
        exit 1
    fi

    youtube_link="$( echo "${properties_list}" | sed $'s/\033[[][^A-Za-z]*m//g' | grep "youtube" | awk '{print $NF'} )"
    echo -e "\n${PURPLE}The youtube link for the machine ${END}${RED}${machine_name}${END} ${PURPLE}is${END} ${RED}${youtube_link}${END}${PURPLE}.${END}"
}


# ---------- Functions for getting machines that match the specified properties ----------

getMachinesNumber() {
    local machines_list="$1"
    total_machines=$( echo "${machines_list}" | wc -w )
    echo -e "${PURPLE}Total machines:${END} ${TURQUOISE}${total_machines}${END}${PURPLE}.${END}\n"
}

getMachinesByDifficulty() {
    local machine_difficulty="$( echo "$1" | sed -e 's/[A-Z]/\L&/g' -e 's/facil/fácil/g' -e 's/dificil/difícil/g' )"
    local machines_list="$( grep -i "Dificultad: \"${machine_difficulty}\"" -B 5 bundle.js | grep "name" | awk '{print $NF}' | tr -d ',' | tr -d '"' | column )"

    # If the difficulty type does not exist or there are not machines for that difficulty type, then exit
    if [ ! "${machines_list}" ]; then
        echo -e "${RED}Difficulty${END} ${GRAY}${machine_difficulty}${END}${RED} is not valid.${END}"
        exit 1
    fi

    if [ "${machine_difficulty}" = "fácil" ]; then
        echo -e "\n${PURPLE}EASY${END}\n"
        difficulty_color=${GREEN}
    fi

    if [ "${machine_difficulty}" = "media" ]; then
        echo -e "\n${PURPLE}MEDIUM${END}\n"
        difficulty_color=${YELLOW}
    fi

    if [ "${machine_difficulty}" = "difícil" ]; then
        echo -e "\n${PURPLE}HARD${END}\n"
        difficulty_color=${ORANGE}
    fi
    
    if [ "${machine_difficulty}" = "insane" ]; then
        echo -e "\n${PURPLE}INSANE${END}\n"
        difficulty_color=${RED}
    fi

    echo -e "${difficulty_color}${machines_list}${END}\n"

    getMachinesNumber "$machines_list"

}

getMachinesByOS() {
    local machine_os="$( echo "$1" | sed 's/[A-Z]/\L&/g' )"
    local machines_list="$( grep -i "so: \"${machine_os}\"" -B 4 bundle.js | grep "name" | awk '{print $NF}' | tr -d ',' | tr -d '"' | column )"

    # If the difficulty type does not exist or there are not machines for that difficulty type, then exit
    if [ ! "${machines_list}" ]; then
        echo -e "${RED}Operating System${END} ${GRAY}${machine_os}${END}${RED} is not valid.${END}"
        exit 1
    fi

    if [ "${machine_os}" = "linux" ]; then
        echo -e "\n${PURPLE}LINUX${END}\n"
        os_color=${GREEN}
    fi

    if [ "${machine_os}" = "windows" ]; then
        echo -e "\n${PURPLE}WINDOWS${END}\n"
        os_color=${BLUE}
    fi

    echo -e "${os_color}${machines_list}${END}\n"

    getMachinesNumber "$machines_list"

}

getMachinesBySkill() {
    skill="$( echo "$1" | sed 's/[A-Z]/\L&/g' )"
    local machines_list="$( grep -i "${skill}" -B 6 bundle.js | grep "name:" | awk '{print $NF}' | tr -d '"' | tr -d ',' | column )"
    
    # If the difficulty type does not exist or there are not machines for that difficulty type, then exit
    if [ ! "${machines_list}" ]; then
        echo -e "${RED}Skill${END} ${GRAY}${skill}${END}${RED} is not valid.${END}"
        exit 1
    fi

    echo -e "\n${PURPLE}${skill}${END}\n\n${TURQUOISE}${machines_list}${END}\n"

    getMachinesNumber "$machines_list"

}

getMachinesByMultipleProperties() {

    function_list=("$@")

    for function in "${function_list[@]}"; do
        list=$( ${function} )

        # This will output all errors
        if [ $? -eq 1 ]; then
            echo "${list}"
            found_error=1
        fi

        machines_lists=("${machines_lists[@]}" "${list}")
    done

    # If at least one error is found, exit
    if [ $found_error ]; then
        exit 1
    fi

    declare -i count=0
    for list in "${machines_lists[@]}"; do 
        uniq_machines_list+="$( echo "${list}" | sed $'s/\033[[][^A-Za-z]*m//g' | head -n -2 | tail -n +4 | tr '[:space:]' '\n' | sort -u )"
        if [ $count -gt 0 ]; then
            uniq_machines_list="$( echo "${uniq_machines_list}" | sort | uniq -d )"
        fi
        let count+=1
    done

    uniq_machines_list="$( echo "${uniq_machines_list}" | column )"

    echo -e "\n${PURPLE}The machines with the specified properties are:${END}\n\n${TURQUOISE}${uniq_machines_list}${END}\n"
    
    getMachinesNumber "$uniq_machines_list"
}

updateFiles() {
    tput civis
    echo -e "\n${PURPLE}Checking for new updates...${END}"
    
    if [ -f bundle.js ]; then
        
        # Check if files need to be updated
        curl -s ${url_bundle} | js-beautify > tmp_bundle.js
        md5_current_bundle_value="$(md5sum bundle.js | awk '{print $1}')"
        md5_new_tmp_bundle_value="$(md5sum tmp_bundle.js | awk '{print $1}')"
        
        if [ ! "${md5_current_bundle_value}" = "${md5_new_tmp_bundle_value}" ]; then
            echo -e "${RED}Files are not up to date.\nUpdating files...${END}"
            cp -f tmp_bundle.js bundle.js
            echo -e "${GREEN}Files are now up to date.${END}"
        else
            echo -e "${GREEN}Files are already up to date.${END}"
        fi

        rm -f tmp_bundle.js
    
    else
        echo -e "${RED}New files must be downloaded.\nDownloading files...${END}"
        curl -s ${url_bundle} | js-beautify > bundle.js
        echo -e "\n${GREEN}All files have been downloaded.${END}"
    fi
    tput cnorm
}

# For using multiple parameters (only for -o, -d and -s)
declare -i machine_filtering=0

while getopts "m:i:y:d:o:s:uh" opts; do
    case "${opts}" in
        m) 
            machine_name="$OPTARG"
            getMachineProperties "${machine_name}"
            ;;
        i)
            machine_ip="$OPTARG"
            getMachineByIP "${machine_ip}"
            ;;
        y)
            machine_name="$OPTARG"
            getYoutubeLink "${machine_name}"
            ;;
        d)
            machine_difficulty="$OPTARG"
            let machine_filtering+=1
            ;;
        o)
            machine_os="$OPTARG"
            let machine_filtering+=2
            ;;
        s)
            skill="$OPTARG"
            let machine_filtering+=4
            ;;
        u)
            updateFiles
            ;;
        h)
            helpPanel
            ;;
        \?|:) 
            echo -e "\n${RED}Error! Use ${END}${GREEN}htb-machines -h${END} ${RED}to see the help panel.${END}\n"
            exit 1
            ;;
    esac
done


if [ $machine_filtering -eq 1 ]; then
    getMachinesByDifficulty "${machine_difficulty}"
fi

if [ $machine_filtering -eq 2 ]; then
    getMachinesByOS "${machine_os}" 
fi

if [ $machine_filtering -eq 3 ]; then
    getMachinesByMultipleProperties "getMachinesByDifficulty ${machine_difficulty}" "getMachinesByOS ${machine_os}"
fi

if [ $machine_filtering -eq 4 ]; then
    getMachinesBySkill "${skill}"
fi

if [ $machine_filtering -eq 5 ]; then 
    getMachinesByMultipleProperties "getMachinesByDifficulty ${machine_difficulty}" "getMachinesBySkill ${skill}"
fi

if [ $machine_filtering -eq 6 ]; then 
    getMachinesByMultipleProperties "getMachinesByOS ${machine_os}" "getMachinesBySkill ${skill}"
fi

if [ $machine_filtering -eq 7 ]; then 
    getMachinesByMultipleProperties "getMachinesByDifficulty ${machine_difficulty}" "getMachinesByOS ${machine_os}" "getMachinesBySkill ${skill}"
fi

