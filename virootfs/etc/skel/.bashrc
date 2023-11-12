export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'

PS1="\n\[$(tput setaf 6)\][ \[$(tput setaf 7)\]\u \[$(tput setaf 6)\]] \[$(tput setaf 6)\][ \[$(tput setaf 5)\]\w \[$(tput setaf 6)\]]\n\[$(tput setaf 3)\]>>> \[$(tput sgr0)\]"

if [ $(command -v fastfetch) ]; then
	fastfetch
fi

if [ $(command -v neofetch) ]; then
	neofetch
fi

if [ $(command -v dfc) ]; then
	dfc -fp /dev -q name
fi
