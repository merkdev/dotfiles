#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias dcd='docker-compose kill && docker-compose rm -f'
