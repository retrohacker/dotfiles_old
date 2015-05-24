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
    "echo 'deb http://httpredir.debian.org/debian/ testing main contrib non-free' >> /etc/apt/sources.list"
else
  runner \
  echo "non-free repo installed, skipping step"
fi
Log 'Migrating to testing'
runner \
  cp /etc/apt/sources.list /etc/sources.list.bak
runner \
  sed -i -e 's/\ \(stable\|wheezy\|jessie\)/\ testing/g' /etc/apt/sources.list
Log 'Updating apt-get'
runner \
  apt-get update
Log 'Downloading new packages'
runner \
  apt-get --download-only -y --force-yes dist-upgrade
Log 'Installing new packages'
runner \
  apt-get dist-upgrade -y --force-yes
heading='true' Log 'Desktop Environment'
Log 'Installing Packages'
runner \
  apt-get install -y --force-yes \
    xserver-xorg-core \
    awesome \
    awesome-extra
heading='true' Log 'Terminal Environment'
Log 'Installing zsh'
runner \
  apt-get install -y --force-yes \
    fonts-powerline \
    zsh
Log 'Setting zsh as default shell'
runner \
  cat /etc/passwd
runner \
  sed -i.bak 's!/bin/bash/!'$(which zsh)'!' /etc/passwd
runner \
  cat /etc/passwd
Log 'Moving zsh dotfiles into place'
runner \
  ln -s ./zsh $HOMEDIR/.zsh
Log 'Installing vim'
runner \
  apt-get install -y --force-yes \
    fonts-powerline \
    vim
Log 'Moving vim dotfiles into place'
runner \
  ln -s ./vim $HOMEDIR/.vim
