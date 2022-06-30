#!/usr/bin/env bash

# based on minimal theme

dark_grey="\[$(tput setaf 8)\]"
light_grey="\[$(tput setaf 248)\]"
SCM_THEME_PROMPT_PREFIX="${dark_grey}[${bold_orange}"
SCM_THEME_PROMPT_SUFFIX="${normal}${dark_grey}]"
SCM_THEME_PROMPT_DIRTY=" ${red}✗"
SCM_THEME_PROMPT_CLEAN=" ${green}✓"

# Max length of PWD to display
MAX_PWD_LENGTH=20

# Displays last X characters of pwd
# copied from hawaii50 theme
function limited_pwd() {

    # Replace $HOME with ~ if possible 
    RELATIVE_PWD=${PWD/#$HOME/\~}

    local offset=$((${#RELATIVE_PWD}-$MAX_PWD_LENGTH))

    if [ $offset -gt "0" ]
    then
        local truncated_symbol="..."
        TRUNCATED_PWD=${RELATIVE_PWD:$offset:$MAX_PWD_LENGTH}
        echo -e "${truncated_symbol}/${TRUNCATED_PWD#*/}"
    else
        echo -e "${RELATIVE_PWD}"
    fi
}

function kube_or_scm() {
    if [[ -n "$KUBECONFIG" && -n "$KUBENAMESPACE" ]]; then
	echo -ne "${light_grey}${KUBECONFIG##*[./]}${dark_grey}.${yellow}${KUBENAMESPACE}"
    else
        echo -ne $(scm_prompt_info)
    fi
}

function prompt() {
  PS1="${underline_orange}nodedev${normal}${dark_grey}:$(kube_or_scm)${reset_color} ${bold_cyan}$(limited_pwd)${reset_color}${normal} "
}

safe_append_prompt_command prompt
