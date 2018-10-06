#!/bin/bash
set -eux

# print environment information.
uname -a
cat /etc/os-release

# upgrade the distribution.
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y
apt-get autoremove -y
apt-get clean -y

# add the vagrant user.
groupadd vagrant
adduser --disabled-password --gecos '' --ingroup vagrant vagrant
usermod -a -G admin vagrant
echo 'vagrant:vagrant' | chpasswd vagrant

# configure the vagrant user shell.
su vagrant -c bash <<'EOF-VAGRANT'
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
EOF-VAGRANT
