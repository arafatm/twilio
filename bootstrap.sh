#!/usr/bin/env bash 

set -e

export DEBIAN_FRONTEND=noninteractive 

USER=

if [[ -z $1 ]]; then
  USER=arafatm
else
  USER=$1
fi

INSTALLED="Installed:\n"

msg() { echo "*" echo "*"
  echo "*****************************************************************"
  echo "*****************************************************************"
  echo "$1"
}

apt() {
  sudo apt-get install -y --force-yes $1
}

apt_3rd_party() {
  # node.js  repo
  if [ ! -f /etc/apt/sources.list.d/nodesource.list ]; then 
    msg "adding node.js repo"
    curl -sL https://deb.nodesource.com/setup | sudo bash -
  fi
}

apt_upgrade() {
  if [ "$[$(date +%s) - $(stat -c %Z /var/cache/apt/pkgcache.bin)]" -ge 3600 ]
  then
    msg "APT update"
    sudo apt-get update
    msg "APT dist-upgrade"
    sudo apt-get dist-upgrade -q -y --force-yes 
    INSTALLED += "- apt-upgrade"
  fi
}

apt_core() {

  pkgs="curl git screen tmux vim zerofree ntpdate"
  pkgs="$pkgs zlib1g-dev build-essential libssl-dev libreadline-dev"
  pkgs="$pkgs libyaml-dev libxml2-dev libxslt1-dev" 
  pkgs="$pkgs libcurl4-openssl-dev python-software-properties nodejs"
  pkgs="$pkgs imagemagick libmagickwand-dev"

  msg "install pkgs"
  apt "$pkgs"
  sudo ntpdate -u pool.ntp.org
}

apt_clean() {
  msg "APT clean"
  sudo apt-get -y autoremove
  sudo apt-get -y clean
  sudo apt-get autoclean -y

  INSTALLED+="- apt-clean"
}

install_postgres() {
  msg "postgresql"
  apt "postgresql libpq-dev postgresql-server-dev-all postgresql-contrib"

  # install pgcrypto module
  #if [[ ! $(sudo -u postgres psql template1 -c '\dx') =~ pgcrypto ]]; then
  #  sudo -u postgres psql template1 -c 'create extension pgcrypto'
  #fi

  # Add rails user with superuser
  msg "Check if rails user allready exists"
  if [[ ! $(sudo -u postgres psql template1 -c '\du') =~ rails ]]; then
    msg "Add rails superuser"
    sudo -u postgres psql template1 -c \
      "create user rails with superuser password 'railspass'"
  fi
  if [[ -d /etc/postgresql/9.1 ]]; then 
    sudo sh -c "echo \"local all postgres  peer\nlocal all all       md5\" \
      > /etc/postgresql/9.1/main/pg_hba.conf" 
  fi
  if [[ -d /etc/postgresql/9.3 ]]; then 
    sudo sh -c "echo \"local all postgres  peer\nlocal all all       md5\" \
      > /etc/postgresql/9.3/main/pg_hba.conf" 
  fi
  msg "restart postgresql"
  sudo /etc/init.d/postgresql restart

  INSTALLED += "- postgres"
}

install_rbenv() {
  if [ ! `which rbenv` ]; then
    msg "installing rbenv"
    git clone git://github.com/sstephenson/rbenv.git $HOME/.rbenv

    msg "rbenv: ruby-build"
    git clone git://github.com/sstephenson/ruby-build.git \
      $HOME/.rbenv/plugins/ruby-build

    msg "rbenv: rbenv-gem-rehash"
    git clone https://github.com/sstephenson/rbenv-gem-rehash.git \
      $HOME/.rbenv/plugins/rbenv-gem-rehash
  else
    msg "updating ruby version"
  fi

  msg "latest ruby"

  rbenv=$HOME/.rbenv/bin/rbenv

  LATEST=`$rbenv install -l | grep '^\s*2.1.*' | grep -v dev | sort | tail -n 1`

  #LATEST='2.1.5'

  # Install a ruby
  if [[ ! $(ruby -v) =~ "ruby $LATEST" ]]; then 
    CONFIGURE_OPTS="--disable-install-doc" $rbenv install -v $LATEST 
    $rbenv global  $LATEST
    $rbenv rehash
    echo "Installed ruby $LATEST"
  else
    echo "ruby $LATEST already installed"
  fi

  INSTALLED+="- rbenv"

  gem install bundler

  bundle install --path vendor

}

install_dotfiles() {
  msg "Installing $USER dotfiles"
  if [[ ! -d $HOME/dotfiles ]]; then 
    msg "installing dotfiles" 
    git clone https://github.com/$USER/dotfiles.git $HOME/dotfiles
    bash $HOME/dotfiles/setup.dotfiles.sh
  else
    msg "updating dotfiles" 
    cd $HOME/dotfiles
    git pull
  fi

  source $HOME/.bashrc
  
  INSTALLED+="- dotfiles"
}

congrats() {
  echo "$INSTALLED"
}

apt_3rd_party
apt_upgrade
apt_core

install_dotfiles
install_postgres
install_rbenv

apt_clean

congrats
