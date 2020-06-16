#!/bin/bash
set -eux

default_wsl_user="${1:-vagrant}"; shift || true

# print environment information.
uname -a
cat /etc/os-release

# upgrade the distribution.
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y
apt-get autoremove -y
apt-get clean -y

# add the default wsl user.
groupadd "$default_wsl_user"
adduser --disabled-password --gecos '' --ingroup "$default_wsl_user" --force-badname "$default_wsl_user"
usermod -a -G admin "$default_wsl_user"
sed -i -E 's,^%admin.+,%admin ALL=(ALL) NOPASSWD:ALL,g' /etc/sudoers

# configure the default wsl user shell.
su "$default_wsl_user" -c bash <<'EOF-DEFAULT-USER'
set -eux

# configure vim.
cat >~/.vimrc <<'EOF'
syntax on
set background=dark
set esckeys
set ruler
set laststatus=2
set nobackup
EOF

# configure bash.
cat >~/.bashrc <<'EOF'
# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

export EDITOR=vim
export PAGER=less

alias l='ls -lF --color'
alias ll='l -a'
alias h='history 25'
alias j='jobs -l'
EOF

# configure readline.
cat >~/.inputrc <<'EOF'
"\e[A": history-search-backward
"\e[B": history-search-forward
"\eOD": backward-word
"\eOC": forward-word
set show-all-if-ambiguous on
set completion-ignore-case on
EOF

# configure git.
git config --global user.email 'rgl@ruilopes.com'
git config --global user.name 'Rui Lopes'
git config --global push.default simple
git config --global core.autocrlf false
EOF-DEFAULT-USER

# configure wsl to use the default wsl user by default.
# NB for this to be applied, you must restart the distro with:
#       wsl.exe --shutdown
cat >/etc/wsl.conf <<EOF
[user]
default=$default_wsl_user
EOF
