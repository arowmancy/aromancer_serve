#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ll="ls -alh"

GIT_PROMPT_SH="git-prompt.sh"

if [[ ! -f "$GIT_PROMPT_SH" ]]; then
  curl "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh" -o $GIT_PROMPT_SH
fi
source $GIT_PROMPT_SH

PROMPT_COMMAND='PS1_CMD1=$(__git_ps1 " (%s)")'
PS1='\u@ttya \w${PS1_CMD1}: '

# ensure key exists
mkdir -m 700 $HOME/.ssh || echo ".ssh directory exists"
if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
  echo "id_ed25519 exists"
else
  ssh-keygen -t ed25519 -f $HOME/.ssh/id_ed25519 -N "" -q
  chown -R default:default .ssh/
fi
