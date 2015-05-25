#!/usr/bin/env bash

# Ensure script is run as root

if [ $UID -ne 0 ]; then
  echo "Script must be run as root"
  exit 1
fi

# Get Working Directory

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Get Logged In User and Homedir

USERNAME=$(who am i | awk '{print $1}')
HOMEDIR=$(eval echo ~$USERNAME)

# Import Dependencies

source "$DIR/infinity/lib/oo-framework.sh"

# Useful Functions

logger() {
  if [ -z "$heading" ]; then
    echo "# $*"
  else
    echo "## $*"
  fi
}

runner() {
  echo "Running \`$*\`"
  echo "\`\`\`"
  bash -c "$*"
  echo "\`\`\`"
}

# Setup Logging

namespace setup_script
Log.RegisterLogger STATUS logger
Log.AddOutput setup_script STATUS

# Run Setup

heading='true' Log 'Updating System'
Log 'Including non-free packages'
# Don't error when sources.list.d is empty
shopt -s nullglob
NONFREE=$(cat /etc/apt/sources.list /etc/apt/sources.list.d/* | grep -v '^#' | grep 'deb.*main.*contrib.*non-free')
shopt -u nullglob
if [ -z "$NONFREE" ]; then
  # quoted to ensure >> gets run inside of runner
  runner \
    "echo 'deb http://httpredir.debian.org/debian/ jessie main contrib non-free' >> /etc/apt/sources.list"
else
  runner \
  echo "non-free repo installed, skipping step"
fi
Log 'Updating apt-get'
runner \
  apt-get update
Log 'Downloading new packages'
runner \
  DEBIAN_FRONTEND=noninteractive apt-get --download-only -y --force-yes upgrade
Log 'Installing new packages'
runner \
  DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes upgrade
heading='true' Log 'Desktop Environment'
Log 'Installing Packages'
runner \
  apt-get install -y --force-yes \
    xorg \
    consolekit \
    awesome \
    awesome-extra
heading='true' Log 'Setting up hardware'
Log 'Installing wireless drivers'
runner \
  apt-get install -y --force-yes \
    firmware-iwlwifi
runner \
  modprobe -r iwlwifi; \
  modprobe iwlwifi
Log 'Installing wicd wireless manager'
runner \
  apt-get install -y --force-yes \
    wicd
heading='true' Log 'Terminal Environment'
Log 'Installing zsh'
runner \
  apt-get install -y --force-yes \
    fonts-powerline \
    zsh
Log 'Setting zsh as default shell'
runner \
  cat /etc/passwd
sed -i.bak 's!/bin/bash!'$(which zsh)'!' /etc/passwd
runner \
  cat /etc/passwd
Log 'Moving zsh dotfiles into place'
runner \
  ln -s $DIR/zsh $HOMEDIR/.zsh
runner \
  ln $DIR/zsh/.zshrc $HOMEDIR/.zshrc
Log 'Installing vim'
runner \
  apt-get install -y --force-yes \
    fonts-powerline \
    vim
Log 'Moving vim dotfiles into place'
runner \
  ln -s $DIR/vim $HOMEDIR/.vim
runner \
  ln $DIR/vim/.vimrc $HOMEDIR/.vimrc
Log 'Moving .Xresources into place'
runner \
  ln -s $DIR/xterm/.Xresources $HOMEDIR/.Xresources
Log 'Moving .xinitrc into place'
runner \
  ln -s $DIR/xterm/.xinitrc $HOMEDIR/.xinitrc
