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

# Get list of users that can log in

USERS=$(exec $DIR/users.sh | grep "^user:" | awk -F":" '{ print $2 }')

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
Log 'Installing backlight manager'
runner \
  apt-get install -y --force-yes \
    xbacklight
Log 'Setting up audio'
runner \
  apt-get install -y --force-yes \
    libasound2 \
    libasound2-doc \
    alsa-base \
    alsa-utils \
    alsa-oss
Log 'Adding users to audio group'
for u in $USERS; do
  runner \
    id $u
  runner \
    usermod -aG audio $u
  runner \
    id $u
done
Log 'Moving asoundrc into place'
  runner \
    ln $DIR/xterm/.asoundrc $HOME/.asoundrc
heading='true' Log 'Terminal Environment'
Log 'Installing htop'
runner \
  apt-get install -y --force-yes \
    htop
Log 'Installing zsh'
runner \
  apt-get install -y --force-yes \
    fonts-powerline \
    zsh
Log 'Setting zsh as default shell'
for u in $USERS; do
  runner \
    grep "^$u" /etc/passwd
  runner \
    chsh -s $(which zsh) $u
  runner \
    grep "^$u" /etc/passwd
done
Log 'Moving zsh dotfiles into place'
runner \
  ln -s $DIR/zsh $HOMEDIR/.zsh
runner \
  ln $DIR/zsh/.zshrc $HOMEDIR/.zshrc
Log 'Installing Text Editors'
runner \
  apt-get install -y --force-yes \
    fonts-powerline \
    vim \
    gedit
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
heading=true Log 'Installing User Programs'
Log 'Installing image editors'
runner \
  apt-get install -y --force-yes \
    gimp \
    gimp-plugin-registry \
    inkscape
Log 'Installing 3D Programs'
runner \
  apt-get install -y --force-yes \
    freecad \
    blender
Log 'Installing Media Programs'
runner \
  apt-get install -y --force-yes \
    digikam \
    ksnapshot \
    vlc
Log 'Installing Web Browser'
runner \
  apt-get install -y --force-yes \
    gdebi
runner \
  gdebi -n \
    $DIR/chrome/google_chrome.deb
Log 'Installing Dropbox'
runner \
  apt-get install -y --force-yes \
    python-gpgme
runner \
  gdebi -n \
    $DIR/dropbox/dropbox.deb
Log 'Installing docker'
runner \
  curl -sSL https://get.docker.com/ | sh
runner \
  groupadd docker
runner \
  gpasswd -a $USERNAME docker
runner \
  service docker restart
Log 'Installing Virtualbox'
runner \
  apt-get install -y --force-yes \
    linux-headers-$(uname -r|sed 's,[^-]*-[^-]*-,,') \
    virtualbox
Log 'Installing iojs'
runner \
  "curl -sL https://deb.nodesource.com/setup_iojs_2.x | sudo bash -"
runner \
  apt-get install -y --force-yes \
    iojs \
    build-essential
Log 'Installing postgresl client'
runner \
  apt-get install -y --force-yes \
    postgresql-client
